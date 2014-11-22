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

-(instancetype)initWithDelegate:(id<MeterViewControllerDelegate>)delegate {
    self = [super init];
    self.delegate = delegate;
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

#define cg(nx,ny,nw,nh) CGRectMake(nx*w,ny*h,nw*w,nh*h)
#define mb(x,y,w,h,s) [self makeButton:cg(x,y,w,h) cb:@selector(s)]
    
    self.ch1_view = [[ChannelView alloc]initWithFrame:cg(0, 0, 6, 4) ch:1];
    [v addSubview:self.ch1_view];
    
    self.ch2_view = [[ChannelView alloc]initWithFrame:cg(0, 4, 6, 4) ch:2];
    [v addSubview:self.ch2_view];
    
    UIView* sv = [[UIView alloc] initWithFrame:cg(0, 8, 6, 2)];
    sv.userInteractionEnabled = YES;
    [[sv layer] setBorderWidth:5];
    [[sv layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    
    self.rate_auto_button        = mb(0,0,1,1,rate_auto_button_press);
    self.rate_button             = mb(1,0,2,1,rate_button_press);
    self.logging_button          = mb(3,0,3,1,logging_button_press);
    self.depth_auto_button       = mb(0,1,1,1,depth_auto_button_press);
    self.depth_button            = mb(1,1,2,1,depth_button_press);
    self.logging_settings_button = mb(3,1,3,1,logging_settings_button_press);
    
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
    g_meter->disp_settings.rate_auto = !g_meter->disp_settings.rate_auto;
    [self refreshAllControls];
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
            [self refreshAllControls];
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
    [self.logging_button setBackgroundColor:[UIColor lightGrayColor]];
}
-(void)depth_auto_button_press {
    g_meter->disp_settings.depth_auto = !g_meter->disp_settings.depth_auto;
    [self refreshAllControls];
}
-(void)depth_auto_button_refresh {
    [MeterViewController style_auto_button:self.depth_auto_button on:g_meter->disp_settings.depth_auto];
}
-(void)depth_button_press {
    if(g_meter->disp_settings.depth_auto) {
        // If auto is on, do nothing
    } else {
        uint8 depth_setting = g_meter->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2;
        depth_setting++;
        // FIXME:  Something is broken when requesting buffers of 256
        depth_setting %= 8;
        g_meter->meter_settings.rw.calc_settings &= ~METER_CALC_SETTINGS_DEPTH_LOG2;
        g_meter->meter_settings.rw.calc_settings |= depth_setting;
        [g_meter sendMeterSettings:^(NSError *error) {
            [self refreshAllControls];
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
    [self.logging_settings_button setBackgroundColor:[UIColor lightGrayColor]];
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
    // Display done.  Check the meter settings.
    g_meter->meter_settings.rw.target_meter_state = METER_PAUSED;
    // Preserve the depth setting, overwrite other calc settings
    g_meter->meter_settings.rw.calc_settings &= METER_CALC_SETTINGS_DEPTH_LOG2;
    //g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_MS|METER_CALC_SETTINGS_MEAN|METER_CALC_SETTINGS_ONESHOT;
    g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_MEAN;
    
    [g_meter sendMeterSettings:^(NSError *error) {
        [self refreshAllControls];
        if(error) {
            DLog(@"Send meter settings error!");
        } else {
            [self play];
        }
    }];
}

-(BOOL)shouldAutorotate { return YES; }
- (NSUInteger)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{ return UIInterfaceOrientationPortrait; }

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        NSLog(@"Seguing to graph");
        [self pause];
        [self.delegate handleMeterViewRotation];
    }
}

-(void) play {
    NSLog(@"In Play");
    if( !self->play ) {
        self->play = YES;
        [g_meter enableStreamMeterBuf:NO cb:^(NSError *error) {
            [g_meter enableStreamMeterSample:YES cb:^(NSError *error) {
                g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
                [g_meter sendMeterSettings:^(NSError *error) {
                    NSLog(@"%@",error);
                }];
            } update:^() {
                [self updateReadings];
            }];
        } complete_buffer_cb:nil];
    }
}

-(void) pause {
    self->play = NO;
    g_meter->meter_settings.rw.target_meter_state = METER_PAUSED;
    [g_meter sendMeterSettings:^(NSError *error) {
        NSLog(@"Paused!");
    }];
}

+(NSString*) formatReading:(double)val digits:(SignificantDigits)digits {
    // TODO: Prefixes for units.  This will fail for wrong values of digits
    BOOL neg = val<0;
    int left = digits.high;
    int right = -1*(digits.high-digits.n_digits);
    NSString* formatstring = [NSString stringWithFormat:@"%@%%0%d.%df", neg?@"":@" ", left+right+neg?0:1, right];
    return [NSString stringWithFormat:formatstring, val];
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
    
    [self.ch1_view value_label_refresh];
    [self.ch2_view value_label_refresh];
}

@end
