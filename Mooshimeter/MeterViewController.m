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
    self.view.backgroundColor = [UIColor whiteColor];
    
    float h = (self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height)/10;
    float w = (self.view.bounds.size.width)/6;
    
    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, w, h)];

#define cg(x,y,w,h) CGRectMake(x,y,w,h)
#define mb(x,y,w,h,s) [self makeButton:cg(x,y,w,h) cb:@selector(s)]
    
    self.ch1_view = [[ChannelView alloc]initWithFrame:cg(0, 0, 6*w, 4*h)];
    self.ch1_view->channel = 1;
    [v addSubview:self.ch1_view];
    
    self.ch2_view = [[ChannelView alloc]initWithFrame:cg(0, 4*h, 6*w, 4*h)];
    self.ch2_view->channel = 2;
    [v addSubview:self.ch2_view];
    
    // TODO: Maybe break this out in to another subclass?
    
    UIView* sv = [[UIView alloc] initWithFrame:CGRectMake(0, 8*h, 6*w, 2*h)];
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
    
    // Display done.  Check the meter settings.
    g_meter->meter_settings.rw.calc_settings = 6;
    LockManager* lm = [[LockManager alloc]init];
    
    self.lock_manager = lm;

    [g_meter sendMeterSettings:nil cb:nil arg:nil];
    
    [self play];
}

-(UIButton*)makeButton:(CGRect)frame cb:(SEL)cb {
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
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
    NSLog(@"Detail View about to appear");
    }

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_ONESHOT;
    [g_meter sendMeterSettings:nil cb:nil arg:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"Detail view preparing to die!");
    [self pause];
}


- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"Goodbye from the detail view!");
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

-(void) refreshAllControls {
    // Make all controls reflect the state of the meter
    
    
}

-(void) play {
    NSLog(@"In Play");
    if( ! self->play ) {
        [g_meter enableStreamMeterBuf:nil cb:nil arg:nil];
        [g_meter setBufferReceivedCallback:self cb:@selector(updateReadings) arg:nil];
        g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
        [g_meter sendMeterSettings:nil cb:nil arg:nil];
        self->play = YES;
    }
}

-(void) pause {
    self->play = NO;
    //[g_meter stopStreamMeterSample];
    [g_meter disableStreamMeterBuf];
}

-(NSString*) formatReading:(double)val resolution:(double)resolution unit:(NSString*)unit {
    // If resolution is 0, autoscale the reading
    if(resolution == 0.0) {
        int log_thou = 0;
        // Normalize to be in the 1-1000 range
        while(fabs(val) >= 1e3) {
            log_thou++;
            val /= 1000.0;
            if(abs(log_thou)==4) break;
        }
        while(fabs(val) <= 1.0) {
            log_thou--;
            val *= 1000.0;
            if(abs(log_thou)==1) break;
        }
        const NSString* small[] = {@"m", @"u", @"n", @"p"};
        const NSString* big[]   = {@"k", @"M", @"G", @"T"};
        const NSString* prefix;
        if(      log_thou > 0 ) prefix = big[    log_thou -1];
        else if( log_thou < 0 ) prefix = small[(-log_thou)-1];
        else                    prefix = @"";
        NSString* retval = @"";
        retval = [retval stringByAppendingString:[NSString stringWithFormat:@"%.3f%@%@", val, prefix, unit]];
        return retval;
    } else {
        // Work out the number of decimal places from the supplied resolution
        int n_decimal = 0;
        double tmp = 1.0;
        while( tmp > resolution ) {
            tmp /= 10.0;
            n_decimal++;
        }
        NSString* formatstring = [NSString stringWithFormat:@"%%.%df%%@", n_decimal];
        NSString* retval = [NSString stringWithFormat:formatstring, val, unit];
        return retval;
    }
}

-(void) trig {
    // Trigger the next conversion
    g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    [g_meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
#if 0
    if(g_meter->disp_settings.ch1Off) {
        self.CH1ValueLabel.text = @"";
        self.CH1Label.text = @"";
    } else {
        // Quick and dirty hack to catch overload values for resistance
        // Since no other measurement will go in to the millions we can hack like this
        if( [g_meter getCH1BufAvg] > 5e6 ) {
            self.CH1ValueLabel.text = @"Overload";
        } else {
            //if( g_meter->ADC_settings.str.ch1set && 0x0F == 0x00 ) {
            self.CH1ValueLabel.text = [self formatReading:[g_meter getCH1BufAvg] resolution:1e-4 unit:[g_meter getCH1Units] ];
        }
        self.CH1Label.text = [g_meter getCH1Label];
    }
    
    if(g_meter->disp_settings.ch2Off) {
        self.CH2ValueLabel.text = @"";
        self.CH2Label.text = @"";
    } else {
        if( [g_meter getCH2Value] > 5e6 ) {
            self.CH2ValueLabel.text = @"Overload";
        } else {
            self.CH2ValueLabel.text = [self formatReading:[g_meter getCH2BufAvg] resolution:1e-5 unit:[g_meter getCH2Units] ];
        }
        self.CH2Label.text = [g_meter getCH2Label];
    }

    self.CH1Raw.text = [NSString stringWithFormat:@"%06X",[g_meter getBufAvg:g_meter->sample_buf.CH1_buf]];
    self.CH2Raw.text = [NSString stringWithFormat:@"%06X",[g_meter getBufAvg:g_meter->sample_buf.CH2_buf]];
    
#endif
    //[self performSelector:@selector(trig) withObject:nil afterDelay:1];
    g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    [g_meter sendMeterSettings:nil cb:nil arg:nil];
}

@end
