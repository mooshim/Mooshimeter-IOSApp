/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

#import "MeterVC.h"
#import "PopupMenu.h"
#import "SmartNavigationController.h"
#import "MeterPreferenceVC.h"
#import "WidgetFactory.h"
#import "GCD.h"
#import "LoggingPreferencesVC.h"
#import "UIView+Toast.h"

@implementation MeterVC

////////////////////
// Lifecycle
////////////////////

-(instancetype)initWithMeter:(MooshimeterDeviceBase *)meter{
    self = [super init];
    self.meter = meter;
    self.speaker = [[SpeaksOnLargeChange alloc]init];
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.nrow = 11;
    self.ncol = 6;

    UIView* v = self.content_view;

#define cg(nx,ny,nw,nh) [self makeRectInGrid:nx row_off:ny width:nw height:nh]
#define mb(x,y,w,h,s) [self makeButton:cg(x,y,w,h) cb:@selector(s)]
    
    self.ch1_view = [[ChannelView alloc]initWithFrame:cg(0, 0, 6, 4) ch:0 meter:self.meter];
    [v addSubview:self.ch1_view];
    
    self.ch2_view = [[ChannelView alloc]initWithFrame:cg(0, 4, 6, 4) ch:1 meter:self.meter];
    [v addSubview:self.ch2_view];
    
    UIView* sv = [[UIView alloc] initWithFrame:cg(0, 8, 6, 3)];
    sv.userInteractionEnabled = YES;

    self.math_label = [[UILabel alloc] initWithFrame:cg(0,0,4,1)];
    self.math_label.textColor = [UIColor blackColor];
    self.math_label.textAlignment = NSTextAlignmentCenter;
    self.math_label.font = [UIFont fontWithName:@"Courier New" size:65];
    self.math_label.text = @"LOADING";
    self.math_label.adjustsFontSizeToFitWidth = YES;
    self.math_label.layer.borderWidth = 1;

    self.math_button             = mb(4,0,2,1,math_button_press);

    self.rate_button             = mb(0,1,3,1,rate_button_press);
    self.depth_button            = mb(3,1,3,1,depth_button_press);
    self.logging_button          = mb(0,2,3,1,logging_button_press);
    self.graph_button            = mb(3,2,3,1,graph_button_press);

    [self.graph_button setTitle:@"GRAPH" forState:UIControlStateNormal];

    [sv addSubview:self.math_label];
    [sv addSubview:self.math_button];
    [sv addSubview:self.rate_button];
    [sv addSubview:self.logging_button];
    [sv addSubview:self.depth_button];
    [sv addSubview:self.graph_button];
#undef cg
#undef mb

    // Dan notes: Connected icon looks like power.  Maybe use something more radio-y?
    // Try to use standard settings presentation?
    // Way to clear buffer in graph mode?

    [v addSubview:sv];
    [self.view addSubview:v];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.meter pause];
    [self.meter removeDelegate:self];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Display done.  Check the meter settings.
    [self.meter addDelegate:self];
    [self.meter stream];
    [self refreshAllControls];
}

////////////////////
// BaseVC callbacks
////////////////////

-(void)populateNavBar {
    // Called from base class, overridden to give custom navbar behavior
    SmartNavigationController *nav = [SmartNavigationController getSharedInstance];
    CGRect nav_size = nav.navigationBar.bounds;
    int x = nav_size.size.width;

    x-=60;
    CGRect s = CGRectMake(x,0,60,nav_size.size.height);
    s.origin.x = x;
    s = CGRectInset(s,5,5);

    // Add settings button to navbar
    MooshimeterDeviceBase * meter = self.meter;
    UIButton* b = [WidgetFactory makeButton:@"\u2699" callback:^{
        SmartNavigationController * gnav = [SmartNavigationController getSharedInstance];
        MeterPreferenceVC * vc = [[MeterPreferenceVC alloc] initWithMeter:meter];
        [gnav pushViewController:vc animated:YES];
    }];
    [b setFrame:CGRectMake(0,0,35,35)];
    [self addToNavBar:b];

    UIImageView* bat_icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bat_icon_0.png"]];
    x-=bat_icon.bounds.size.width;
    s = CGRectMake(0,0,bat_icon.bounds.size.width,bat_icon.bounds.size.height);
    [bat_icon setFrame:s];
    [self addToNavBar:bat_icon];
    self.bat_icon = bat_icon;

    UIImageView* sig_icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sig_icon_0.png"]];
    x-=sig_icon.bounds.size.width;
    s = CGRectMake(0,0,sig_icon.bounds.size.width,sig_icon.bounds.size.height);
    [sig_icon setFrame:s];
    [self addToNavBar:sig_icon];
    self.sig_icon = sig_icon;

    // Use the rest of the space for title
    [self setTitle:[self.meter getName]];
}

//////////////////////
// UIViewController callbacks
//////////////////////

-(BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait; }
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation { return UIInterfaceOrientationPortrait; }

/////////////////
// Button push handlers
/////////////////

-(void)rate_button_press {
    NSMutableArray * options = [[self.meter getSampleRateList] mutableCopy];
    [options addObjectsFromArray:[self.meter getSampleRateList]];
    [PopupMenu displayOptionsWithParent:self.view title:@"Sample Rate" options:[self.meter getSampleRateList] cancel:@"AUTORANGE" callback:^(int i) {
        NSLog(@"Received %d",i);
        if(i>= [[self.meter getSampleRateList]count]) {
            // Cancel button pressed, which we're using for autorange
            self.meter.rate_auto = YES;
        } else {
            self.meter.rate_auto = NO;
            [self.meter setSampleRateIndex:i];
        }
    }];
}
-(void)rate_button_refresh {
    int rate = [self.meter getSampleRateHz];
    NSString* title = [NSString stringWithFormat:@"%dHz", rate];
    [self.rate_button setTitle:title forState:UIControlStateNormal];
    if(self.meter.rate_auto) {
        [WidgetFactory setButtonSubtitle:self.rate_button subtitle:@"AUTO"];
    } else {
        [WidgetFactory setButtonSubtitle:self.rate_button subtitle:@"MANUAL"];
    }
}
-(void)logging_button_press {
    SmartNavigationController * gnav = [SmartNavigationController getSharedInstance];
    LoggingPreferencesVC * vc = [[LoggingPreferencesVC alloc] initWithMeter:self.meter];
    [gnav pushViewController:vc animated:YES];
}
-(void)logging_button_refresh {
    int s = [self.meter getLoggingStatus];
    NSString* title, *subtitle;
    bool logging_ok = s==0;
    title = [self.meter getLoggingOn]?@"Logging:ENABLED":@"Logging:DISABLED";
    subtitle = [self.meter getLoggingStatusMessage];
    [self.logging_button setBackgroundColor:logging_ok?[UIColor whiteColor]:[UIColor lightGrayColor]];
    [self.logging_button setTitle:title forState:UIControlStateNormal];
    [WidgetFactory setButtonSubtitle:self.logging_button subtitle:subtitle];
}
-(void)depth_button_press {
    [PopupMenu displayOptionsWithParent:self.view title:@"Buffer Depth" options:[self.meter getBufferDepthList] cancel:@"AUTORANGE" callback:^(int i) {
        NSLog(@"Received %d", i);
        if(i>= [[self.meter getBufferDepthList]count]){
            self.meter.depth_auto=YES;
        } else {
            self.meter.depth_auto=NO;
            [self.meter setBufferDepthIndex:i];
        }
    }];
}
-(void)depth_button_refresh {
    int depth = [self.meter getBufferDepth];
    NSString* title = [NSString stringWithFormat:@"%dsmpl", depth];
    [self.depth_button setTitle:title forState:UIControlStateNormal];
    if(self.meter.depth_auto) {
        [WidgetFactory setButtonSubtitle:self.depth_button subtitle:@"AUTO"];
    } else {
        [WidgetFactory setButtonSubtitle:self.depth_button subtitle:@"MANUAL"];
    }
}

-(void)math_label_refresh:(MeterReading*)val {
    [self.math_label setText:[val toString]];
}

-(void)graph_button_press {
    NSLog(@"Transition to graph view");
    GraphVC* vc = [[GraphVC alloc] initWithMeter:self.meter];
    //[self.navigationController pushViewController:vc animated:YES];
    [self presentViewController:vc animated:YES completion:^{
        NSLog(@"modal finish");
    }];
}

-(void)math_button_refresh {
    [self.math_button setTitle:[self.meter getInputLabel:MATH] forState:UIControlStateNormal];

}

-(void)math_button_press {
    [PopupMenu displayOptionsWithParent:self.view
                                  title:@"Math Options"
                                options:[self.meter getInputNameList:MATH]
                               callback:^(int i) {
                                   NSLog(@"Received %d", i);
                                   [self.meter setInput:MATH
                                             descriptor:[self.meter getInputList:MATH][i]];
                               }];
}

-(void) refreshAllControls {
    // Make all controls reflect the state of the meter
    [self rate_button_refresh];
    [self depth_button_refresh];
    [self logging_button_refresh];
    [self math_button_refresh];
    [self.ch1_view refreshAllControls];
    [self.ch2_view refreshAllControls];
}

/////////////////
// MooshimeterDelegateProtocol methods
/////////////////
#pragma mark MooshimeterDelegateProtocol methods

- (void)onInit {
    NSLog(@"onInit");
}

- (void)onDisconnect {
    NSLog(@"onDisconnect");
    SmartNavigationController * nav = [SmartNavigationController getSharedInstance];
    [GCD asyncMain:^{
        [nav popToRootViewControllerAnimated:YES];
    }];
}

- (void)onRssiReceived:(int)rssi {
    //Update the title bar
    NSLog(@"rssi:%d",rssi);
    int percent = rssi+100;
    percent=percent>100?100:percent;
    percent=percent<0?0:percent;
    [GCD asyncMain:^{
        [self.sig_icon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"sig_icon_%d.png",percent]]];
    }];
}

- (void)onBatteryVoltageReceived:(float)voltage {
    //Update the title bar
    int percent = (int)((voltage-2)*100);
    percent=percent>100?100:percent;
    percent=percent<0?0:percent;

    [GCD asyncMain:^{
        [self.bat_icon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"bat_icon_%d.png",percent]]];
    }];
}

- (void)onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading *)val {
    // Cache values to determine if change is large enough to speak about
    [GCD asyncMain:^{
        switch(c) {
            case CH1:{
                [self.ch1_view value_label_refresh:val];
                break;}
            case CH2:{
                [self.ch2_view value_label_refresh:val];
                // Handle autoranging
                if([self.meter applyAutorange]) {
                    // Something changed, refresh to be safe
                    [self refreshAllControls];
                }
                break;}
            case MATH:{
                [self math_label_refresh:val];
                break;}
        }
    }];
    // Handle speech
    if(self.meter.speech_on[c]) {
        [self.speaker decideAndSpeak:val];
    }
}

- (void)onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber *> *)val {
    NSLog(@"Shouldn't receive a buffer in MeterVC");
}

- (void)onSampleRateChanged:(int)sample_rate_hz {
    [self performSelectorOnMainThread:@selector(rate_button_refresh) withObject:nil  waitUntilDone:NO];
}

- (void)onBufferDepthChanged:(int)buffer_depth {
    [self performSelectorOnMainThread:@selector(depth_button_refresh) withObject:nil  waitUntilDone:NO];
}

- (void)onLoggingStatusChanged:(BOOL)on new_state:(int)new_state message:(NSString *)message {
    [self performSelectorOnMainThread:@selector(logging_button_refresh) withObject:nil  waitUntilDone:NO];
}

- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {
    switch(c) {
        case CH1:
            {[GCD asyncMain:^{[self.ch1_view range_button_refresh];}];}
            break;
        case CH2:
            {[GCD asyncMain:^{[self.ch2_view range_button_refresh];}];}
            break;
        case MATH:
            NSLog(@"TODO");
            break;
    }
}

- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {
    switch(c) {
        case CH1:
            {[GCD asyncMain:^{[self.ch1_view display_set_button_refresh];}];}
        break;
        case CH2:
            {[GCD asyncMain:^{[self.ch2_view display_set_button_refresh];}];}
        break;
        case MATH:
        {[GCD asyncMain:^{[self math_button_refresh];}];}
        break;
    }
}

- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {
    switch(c) {
        case CH1:
            {[GCD asyncMain:^{[self.ch1_view zero_button_refresh];}];}
            break;
        case CH2:
            {[GCD asyncMain:^{[self.ch2_view zero_button_refresh];}];}
            break;
        case MATH:
            NSLog(@"IMPOSSIBRUUU");
            break;
    }
}


@end
