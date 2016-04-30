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

#import "MeterViewController.h"
#import "PopupMenu.h"

@implementation MeterViewController

-(BOOL)prefersStatusBarHidden { return YES; }

-(instancetype)initWithMeter:(MooshimeterDeviceBase *)meter{
    self = [super init];
    self.meter = meter;
    self.play = NO;
    return self;
}


- (void)viewDidLoad
{
    NSLog(@"Meter view loaded!");
    [super viewDidLoad];

    float h = (self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height)/10;
    float w = (self.view.bounds.size.width)/6;
    
    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, 6*w, 10*h)];
    v.userInteractionEnabled = YES;
    v.backgroundColor = [UIColor whiteColor];

#define cg(nx,ny,nw,nh) CGRectMake(nx*w,ny*h,nw*w,nh*h)
#define mb(x,y,w,h,s) [self makeButton:cg(x,y,w,h) cb:@selector(s)]
    
    self.ch1_view = [[ChannelView alloc]initWithFrame:cg(0, 0, 6, 4) ch:0 meter:self.meter];
    [v addSubview:self.ch1_view];
    
    self.ch2_view = [[ChannelView alloc]initWithFrame:cg(0, 4, 6, 4) ch:1 meter:self.meter];
    [v addSubview:self.ch2_view];
    
    UIView* sv = [[UIView alloc] initWithFrame:cg(0, 8, 6, 2)];
    sv.userInteractionEnabled = YES;
    [[sv layer] setBorderWidth:5];
    [[sv layer] setBorderColor:[UIColor blackColor].CGColor];
    
    self.rate_auto_button        = mb(0,0,1,1,rate_auto_button_press);
    self.rate_button             = mb(1,0,2,1,rate_button_press);
    self.logging_button          = mb(3,0,3,1,logging_button_press);
    self.depth_auto_button       = mb(0,1,1,1,depth_auto_button_press);
    self.depth_button            = mb(1,1,2,1,depth_button_press);
    self.zero_button             = mb(3,1,3,1,zero_button_press);
    
    [self.zero_button setTitle:@"Zero" forState:UIControlStateNormal];
    
    [sv addSubview:self.rate_auto_button];
    [sv addSubview:self.rate_button];
    [sv addSubview:self.logging_button];
    [sv addSubview:self.depth_auto_button];
    [sv addSubview:self.depth_button];
    [sv addSubview:self.zero_button];
#undef cg
#undef mb
    
    [v addSubview:sv];
    [self.view addSubview:v];
}

-(void) viewWillDisappear:(BOOL)animated {
    [self pause];
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

-(void)rate_auto_button_press{
    self.meter.rate_auto = !self.meter.rate_auto;
    [self refreshAllControls];
}
-(void)rate_auto_button_refresh{
    [MeterViewController style_auto_button:self.rate_auto_button on:self.meter.rate_auto];
}
-(void)rate_button_press {
    // TODO: Add autorange handling
    [PopupMenu displayOptionsWithParent:self.view title:@"Sample Rate" options:[self.meter getSampleRateList] callback:^(int i) {
        NSLog(@"Received %d",i);
        [self.meter setSampleRateIndex:i];
        [self refreshAllControls];
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
-(void)depth_auto_button_press {
    self.meter.depth_auto = !self.meter.depth_auto;
    [self refreshAllControls];
}
-(void)depth_auto_button_refresh {
    [MeterViewController style_auto_button:self.depth_auto_button on:self.meter.depth_auto];
}
-(void)depth_button_press {
    [PopupMenu displayOptionsWithParent:self.view title:@"Buffer Depth" options:[self.meter getBufferDepthList] callback:^(int i) {
        NSLog(@"Received %d", i);
        [self.meter setBufferDepthIndex:i];
        [self refreshAllControls];
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

-(void) refreshAllControls {
    // Make all controls reflect the state of the meter
    [self rate_auto_button_refresh];
    [self rate_button_refresh];
    [self depth_auto_button_refresh];
    [self depth_button_refresh];
    [self logging_button_refresh];
    [self.ch1_view refreshAllControls];
    [self.ch2_view refreshAllControls];
}

-(UIButton*)makeButton:(CGRect)frame cb:(SEL)cb {
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b addTarget:self action:cb forControlEvents:UIControlEventTouchUpInside];
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [b setTitle:@"TBD" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[b layer] setBorderWidth:2];
    [[b layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    b.frame = frame;
    return b;
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Meter View about to appear");
    // Display done.  Check the meter settings.
    [self.meter stream];
}

-(BOOL)shouldAutorotate { return YES; }
- (NSUInteger)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{ return UIInterfaceOrientationPortrait; }


-(void) play {
    NSLog(@"In Play");
    [self.meter stream];
}

-(void) pause {
    [self.meter pause];
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
    [self.ch1_view value_label_refresh];
    [self.ch2_view value_label_refresh];
    
    // Handle autoranging
    if([self.meter applyAutorange]) {
        // Something changed, refresh to be safe
        [self refreshAllControls];
    }
}

@end
