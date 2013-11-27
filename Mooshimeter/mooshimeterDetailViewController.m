//
//  mooshimeterDetailViewController.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "mooshimeterDetailViewController.h"

@interface mooshimeterDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation mooshimeterDetailViewController

#pragma mark - Managing the detail item

-(mooshimeterDetailViewController*)init {
    self = [super init];
    self->play = NO;
    return self;
}

- (void)setDevice:(mooshimeter_device*)device
{
    NSLog(@"I am in setDetailItem");
    BUILD_BUG_ON(sizeof(int24) != 3);
    if (self.meter != device) {
        NSLog(@"New device does not match old one!");
        self.meter = device;
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)viewDidLoad
{
    NSLog(@"Detail view trying to display!");
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Detail View about to appear");
    // Stash the present settings... in pure multimeter mode we use pure settings
    self.meter->meter_settings.target_meter_state = METER_RUNNING;
    self->meter_settings = self.meter->meter_settings;
    self->ADC_settings   = self.meter->ADC_settings;
    // Force a 1kHz sample rate
    self.meter->ADC_settings.str.config1 = 0x03;
    self.meter->meter_settings.buf_depth_log2 = 7;
    self.meter->meter_settings.calc_mean      = 1;
    self.meter->meter_settings.calc_ac        = 1;
    self.meter->meter_settings.calc_freq      = 1;
    [self.meter sendADCSettings:self cb:@selector(viewWillAppear2) arg:nil];
}

-(void) viewWillAppear2 {
    [self.meter sendMeterSettings:self cb:@selector(play) arg:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"Detail view preparing to die!");
    [self pause];
    NSLog(@"Restoring settings...");
    // Stash the present settings... in pure multimeter mode we use pure settings
    self.meter->meter_settings = self->meter_settings;
    self.meter->ADC_settings   = self->ADC_settings;
    [self.meter sendMeterSettings:self cb:@selector(viewWillDisappear2) arg:nil];
}

-(void) viewWillDisappear2 {
    [self.meter sendADCSettings:nil cb:nil arg:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"Goodbye from the detail view!");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) play {
    NSLog(@"In Play");
    if( ! self->play ) {
        [self.meter startStreamMeterSample:self cb:@selector(updateReadings) arg:nil];
        self->play = YES;
    }
}

-(void) pause {
    self->play = NO;
    [self.meter stopStreamMeterSample];
}

-(NSString*) formatReading:(double)val unit:(NSString*)unit {
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
    //double tmp = val;
    //int i = 0;
    //while(abs(tmp) < 1000) {
    //    retval = [retval stringByAppendingString:@" "];
    //    tmp *= 10;
    //    if(++i == 1) break;
    //}
    //if( val > 0 ) retval = [retval stringByAppendingString:@" "];
    retval = [retval stringByAppendingString:[NSString stringWithFormat:@"%.3f%@%@", val, prefix, unit]];
    return retval;
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
    
    double dispval;
    self.Label1.text = [self formatReading:[self.meter getCH1Value] unit:[self.meter getCH1Units] ];
    
    self.Label0.text = [self formatReading:[self.meter getCH2Value] unit:[self.meter getCH2Units] ];
    
    self.Label3.text = [self formatReading:[self.meter getCH1ACValue] unit:[self.meter getCH1Units] ];
    
    self.Label2.text = [self formatReading:[self.meter getCH2ACValue] unit:[self.meter getCH2Units] ];
    
    dispval = self.meter->meter_sample.ch2_period;
    dispval /= 16;
    dispval *= (1./32768);
    dispval = 1.0/dispval;
    dispval /= 2;
    self.Label4.text = [NSString localizedStringWithFormat:@"%2.2f", dispval];

    //dispval = adjusted.power_factor;
    //dispval /= (1<<15);
    //NSLog(@"Q: %f", dispval);
    //self.Label5.text = [NSString localizedStringWithFormat:@"%3.3f", dispval];
    
    //[self performSelector:@selector(reqUpdate) withObject:nil afterDelay:0.2];
}

@end
