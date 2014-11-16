//
//  mooshimeterDetailViewController.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "MeterViewController.h"

dispatch_semaphore_t tmp_sem;

@implementation MeterViewController

-(BOOL)prefersStatusBarHidden { return YES; }

-(MeterViewController*)init {
    self = [super init];
    self->play = NO;
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

#define cg(x,y,w,h) CGRectMake(x,y,w,h)
#define mb(x,y,w,h,s) [self makeButton:cg(x,y,w,h) cb:@selector(s)]
    
    self.ch1_view = [[ChannelView alloc]initWithFrame:cg(0, 0, 6*w, 4*h) ch:1];
    [v addSubview:self.ch1_view];
    
    self.ch2_view = [[ChannelView alloc]initWithFrame:cg(0, 4*h, 6*w, 4*h) ch:2];
    [v addSubview:self.ch2_view];
    
    // TODO: Maybe break this out in to another subclass?
    
    UIView* sv = [[UIView alloc] initWithFrame:CGRectMake(0, 8*h, 6*w, 2*h)];
    sv.userInteractionEnabled = YES;
    [[sv layer] setBorderWidth:5];
    [[sv layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    
    self.rate_auto_button        = mb(  0,0,  w,h,rate_auto_button_press);
    self.rate_button             = mb(  w,0,2*w,h,rate_button_press);
    self.logging_button          = mb(3*w,0,3*w,h,logging_button_press);
    self.depth_auto_button       = mb(  0,h,  w,h,depth_auto_button_press);
    self.depth_button            = mb(  w,h,2*w,h,depth_button_press);
    self.logging_settings_button = mb(3*w,h,3*w,h,logging_settings_button_press);
    
    [sv addSubview:self.rate_auto_button];
    [sv addSubview:self.rate_button];
    [sv addSubview:self.logging_button];
    [sv addSubview:self.depth_auto_button];
    [sv addSubview:self.depth_button];
    [sv addSubview:self.logging_settings_button];
#undef cg
#undef mb
    [v addSubview:sv];
    [self.view addSubview:v];
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
    g_meter->disp_settings.rate_auto = !g_meter->disp_settings.rate_auto;
    [self rate_auto_button_refresh];
}
-(void)rate_auto_button_refresh{
    [MeterViewController style_auto_button:self.rate_auto_button on:g_meter->disp_settings.rate_auto];
}
-(void)rate_button_press {
    if(g_meter->disp_settings.rate_auto) {
        // If auto is on, do nothing
    } else {
        uint8 rate_setting = g_meter->meter_settings.rw.adc_settings & ADC_SETTINGS_SAMPLERATE_MASK;
        rate_setting++;
        rate_setting %= 7;
        g_meter->meter_settings.rw.adc_settings &= ~ADC_SETTINGS_SAMPLERATE_MASK;
        g_meter->meter_settings.rw.adc_settings |= rate_setting;
        [g_meter sendMeterSettings:^(NSError *error) {
            [self rate_button_refresh];
        }];
    }
}
-(void)rate_button_refresh {
    uint8 rate_setting = g_meter->meter_settings.rw.adc_settings & ADC_SETTINGS_SAMPLERATE_MASK;
    int rate = 125 * (1<<rate_setting);
    NSString* title = [NSString stringWithFormat:@"%dHz", rate];
    [self.rate_button setTitle:title forState:UIControlStateNormal];
    if(g_meter->disp_settings.rate_auto) {
        [self.rate_button setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.rate_button setBackgroundColor:[UIColor whiteColor]];
    }
}
-(void)logging_button_press {
    DLog(@"Press");
}
-(void)logging_button_refresh {
    DLog(@"Disp");
}
-(void)depth_auto_button_press {
    DLog(@"Press");
    g_meter->disp_settings.depth_auto = !g_meter->disp_settings.depth_auto;
    [self depth_auto_button_refresh];
}
-(void)depth_auto_button_refresh {
    DLog(@"Disp");
    [MeterViewController style_auto_button:self.depth_auto_button on:g_meter->disp_settings.depth_auto];
}
-(void)depth_button_press {
    if(g_meter->disp_settings.depth_auto) {
        // If auto is on, do nothing
    } else {
        uint8 depth_setting = g_meter->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2;
        depth_setting++;
        depth_setting %= 9;
        g_meter->meter_settings.rw.calc_settings &= ~METER_CALC_SETTINGS_DEPTH_LOG2;
        g_meter->meter_settings.rw.calc_settings |= depth_setting;
        [g_meter sendMeterSettings:^(NSError *error) {
            [self depth_button_refresh];
        }];
    }
}
-(void)depth_button_refresh {
    uint8 depth_setting = g_meter->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2;
    int depth = (1<<depth_setting);
    NSString* title = [NSString stringWithFormat:@"%dsmpl", depth];
    [self.depth_button setTitle:title forState:UIControlStateNormal];
    if(g_meter->disp_settings.depth_auto) {
        [self.depth_button setBackgroundColor:[UIColor lightGrayColor]];
    } else {
        [self.depth_button setBackgroundColor:[UIColor whiteColor]];
    }
}
-(void)logging_settings_button_press {
    DLog(@"Press");
}
-(void)logging_settings_button_refresh {
    DLog(@"Disp");
}


-(void) refreshAllControls {
    // Make all controls reflect the state of the meter
    [self rate_auto_button_refresh];
    [self rate_button_refresh];
    [self depth_auto_button_refresh];
    [self depth_button_refresh];
    [self logging_button_refresh];
    [self logging_settings_button_refresh];
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
    [[b layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    b.frame = frame;
    return b;
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Meter View about to appear");
    [self refreshAllControls];
    
    // Display done.  Check the meter settings.
    g_meter->meter_settings.rw.target_meter_state = METER_PAUSED;
    g_meter->meter_settings.rw.calc_settings = METER_CALC_SETTINGS_MEAN|METER_CALC_SETTINGS_ONESHOT|6;
    
    [g_meter sendMeterSettings:^(NSError *error) {
        if(error) {
            DLog(@"Send meter settings error!");
        } else {
            [self play];
        }
    }];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"Meter view preparing to die!");
    [self pause];
}


- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"Goodbye from the Meter view!");
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"Signal change to graph here");
}

-(void) play {
    NSLog(@"In Play");
    if( !self->play ) {
        self->play = YES;
        [g_meter enableStreamMeterBuf:YES cb:nil complete_buffer_cb:^{
            [self updateReadings];
        }];
        g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
        [g_meter sendMeterSettings:^(NSError *error) {
            NSLog(error);
        }];
    }
}

-(void) pause {
    self->play = NO;
}

+(NSString*) formatReading:(double)val digits:(SignificantDigits)digits {
    // TODO: Prefixes for units.  This will fail for wrong values of digits
    NSString* neg = val<0? @"":@" ";
    int left = digits.high;
    int right = -1*(digits.high-digits.n_digits);
    NSString* formatstring = [NSString stringWithFormat:@"%@%%0%d.%df", neg, left+right+1, right];
    NSString* retval = [NSString stringWithFormat:formatstring, val];
    return retval;
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
    
    [self.ch1_view value_label_refresh];
    [self.ch2_view value_label_refresh];

    if(self->play) {
        g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
        [g_meter sendMeterSettings:^(NSError *error) {
            NSLog(error);
        }];
    }
}

@end
