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

@implementation MeterVC

-(BOOL)prefersStatusBarHidden { return YES; }

-(instancetype)initWithMeter:(MooshimeterDeviceBase *)meter{
    self = [super init];
    self.meter = meter;
    return self;
}


- (void)viewDidLoad
{
    NSLog(@"Meter view loaded!");
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
    [[sv layer] setBorderWidth:5];
    [[sv layer] setBorderColor:[UIColor blackColor].CGColor];

    self.math_label = [[UILabel alloc] initWithFrame:cg(0,0,4,1)];
    self.math_label.textColor = [UIColor blackColor];
    self.math_label.textAlignment = NSTextAlignmentCenter;
    self.math_label.font = [UIFont fontWithName:@"Courier New" size:65];
    self.math_label.text = @"0.00000";
    self.math_label.adjustsFontSizeToFitWidth = YES;

    self.math_button             = mb(4,0,2,1,math_button_press);

    self.rate_button             = mb(0,1,3,1,rate_button_press);
    self.logging_button          = mb(3,1,3,1,logging_button_press);
    self.depth_button            = mb(0,2,3,1,depth_button_press);
    self.graph_button            = mb(3,2,3,1,graph_button_press);

    [self.graph_button setTitle:@"OPEN GRAPH" forState:UIControlStateNormal];

    [sv addSubview:self.math_label];
    [sv addSubview:self.math_button];
    [sv addSubview:self.rate_button];
    [sv addSubview:self.logging_button];
    [sv addSubview:self.depth_button];
    [sv addSubview:self.graph_button];
#undef cg
#undef mb

    [v addSubview:sv];
    [self.view addSubview:v];

    [self.meter addDelegate:self];
}

-(void) viewWillDisappear:(BOOL)animated {
    [self.meter pause];
}

+(void)style_auto_button:(UIButton*)b on:(BOOL)on {
    if(on) {
        [b setBackgroundColor:[UIColor greenColor]];
        [b setTitle:@"A" forState:UIControlStateNormal];
    } else {
        [b setBackgroundColor:[UIColor redColor]];
        [b setTitle:@"M" forState:UIControlStateNormal];
    }
}

-(void)rate_auto_button_refresh{
    [MeterVC style_auto_button:self.rate_auto_button on:self.meter.rate_auto];
}
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
        [self.rate_button setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.rate_button setBackgroundColor:[UIColor whiteColor]];
    }
}
-(void)logging_button_press {
    if([self.meter getLoggingStatus]!=0) {
        // Do nothing if there's a logging error
        return;
    }
    [self.meter setLoggingOn:![self.meter getLoggingOn]];
}
-(void)logging_button_refresh {
    int s = [self.meter getLoggingStatus];
    NSString* title;
    bool logging_ok = s==0;
    if(logging_ok) {
        title = [self.meter getLoggingOn]?@"Logging:ON":@"Logging:OFF";
        [self.logging_button setBackgroundColor:[UIColor whiteColor]];
    } else {
        title = [self.meter getLoggingStatusMessage];
        [self.logging_button setBackgroundColor:[UIColor lightGrayColor]];
    }
    [self.logging_button setTitle:title forState:UIControlStateNormal];
}
-(void)depth_auto_button_refresh {
    [MeterVC style_auto_button:self.depth_auto_button on:self.meter.depth_auto];
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
        [self.depth_button setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.depth_button setBackgroundColor:[UIColor whiteColor]];
    }
}

-(void)settings_button_press {
    /*
    if(!self.settings_view) {
        CGRect frame = self.view.frame;
        frame.origin.x += .05*frame.size.width;
        frame.origin.y += (frame.size.height - 250)/2;
        frame.size.width  *= 0.9;
        frame.size.height =  250;
        MeterSettingsView* g = [[MeterSettingsView alloc] initWithFrame:frame];
        [g setBackgroundColor:[UIColor whiteColor]];
        [g setAlpha:0.9];
        self.settings_view = g;
    }
    if([self.view.subviews containsObject:self.settings_view]) {
        [self.settings_view removeFromSuperview];
    } else {
        [self.view addSubview:self.settings_view];
    }*/
}
-(void)settings_button_refresh {
    DLog(@"Disp");
    //[self.settings_button setBackgroundColor:[UIColor lightGrayColor]];
}

-(void)math_label_refresh:(MeterReading*)val {
    [self.math_label setText:[val toString]];
}

-(void)graph_button_press {
    NSLog(@"Transition to graph view");
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
    [self rate_auto_button_refresh];
    [self rate_button_refresh];
    [self depth_auto_button_refresh];
    [self depth_button_refresh];
    [self logging_button_refresh];
    [self math_button_refresh];
    [self.ch1_view refreshAllControls];
    [self.ch2_view refreshAllControls];
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Meter View about to appear");
    // Display done.  Check the meter settings.
    [self.meter stream];
    [self refreshAllControls];
}

-(BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait; }

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{ return UIInterfaceOrientationPortrait; }

#pragma mark MooshimeterDelegateProtocol methods

- (void)onInit {
    NSLog(@"onInit");
}

- (void)onDisconnect {
    NSLog(@"onDisconnect");
    SmartNavigationController * nav = [SmartNavigationController getSharedInstance];
    [nav popToRootViewControllerAnimated:YES];
}

- (void)onRssiReceived:(int)rssi {
    //Update the title bar
}

- (void)onBatteryVoltageReceived:(float)voltage {
    //Update the title bar
}

- (void)onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading *)val {
    NSLog(@"Updating measurements for %d...",c);
    switch(c) {
        case CH1:
            [self.ch1_view value_label_refresh:val];
            break;
        case CH2:
            [self.ch2_view value_label_refresh:val];
            // Handle autoranging
            if([self.meter applyAutorange]) {
                // Something changed, refresh to be safe
                [self refreshAllControls];
            }
            break;
        case MATH:
            [self math_label_refresh:val];
            break;
    }
}

- (void)onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber *> *)val {
    NSLog(@"Shouldn't receive a buffer in MeterVC");
}

- (void)onSampleRateChanged:(int)sample_rate_hz {
    [self rate_button_refresh];
}

- (void)onBufferDepthChanged:(int)buffer_depth {
    [self depth_button_refresh];
}

- (void)onLoggingStatusChanged:(bool)on new_state:(int)new_state message:(NSString *)message {
    [self logging_button_refresh];
}

- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {
    switch(c) {
        case CH1:
            [self.ch1_view range_button_refresh];
            break;
        case CH2:
            [self.ch2_view range_button_refresh];
            break;
        case MATH:
            NSLog(@"TODO");
            break;
    }
}

- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {
    switch(c) {
        case CH1:
            [self.ch1_view display_set_button_refresh];
            break;
        case CH2:
            [self.ch2_view display_set_button_refresh];
            break;
        case MATH:
            [self math_button_refresh];
            break;
    }
}

- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {
    switch(c) {
        case CH1:
            [self.ch1_view zero_button_refresh];
            break;
        case CH2:
            [self.ch2_view zero_button_refresh];
            break;
        case MATH:
            NSLog(@"IMPOSSIBRUUU");
            break;
    }
}


@end
