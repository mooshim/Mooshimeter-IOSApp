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

#import "MeterSettingsView.h"

@implementation MeterSettingsView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.userInteractionEnabled = YES;
    
    // Initialize values and helpers
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIToolbar* name_apply_toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, screenRect.size.width, 50)];
    name_apply_toolbar.barStyle = UIBarStyleDefault;
    name_apply_toolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(nameCancel)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(nameDeselected)],
                           nil];
    [name_apply_toolbar sizeToFit];
    
    UIToolbar* loglen_apply_toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, screenRect.size.width, 50)];
    loglen_apply_toolbar.barStyle = UIBarStyleDefault;
    loglen_apply_toolbar.items = [NSArray arrayWithObjects:
                                [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(loggingTimeSetCancel)],
                                [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(loggingTimeSet)],
                                nil];
    [loglen_apply_toolbar sizeToFit];
    
    //NSArray* freq_options  = [NSArray arrayWithObjects:@"MAX", @"1s", @"10s", @"1m", nil];
    //const uint16 period_values[] = {0, 1000, 10000, 60*1000};
    //self.logging_period_control = [[UISegmentedControl alloc] initWithItems:freq_options];
    
    // Lay out the controls
    const int nrow = 2;
    const int ncol = 1;
    
    float h = frame.size.height/nrow;
    float w = frame.size.width/ncol;
    
#define cg(nx,ny,nw,nh) CGRectMake(nx*w,ny*h,nw*w,nh*h)
    self.name_control            = [[UITextField         alloc]initWithFrame:cg(0,0,1,1)];
    //self.logging_period_control.frame =                                     cg(0,1,1,1);
    //self.logging_time_control   = [[UITextField         alloc]initWithFrame:cg(0,2,1,1)];
    self.hibernate_button        = [[UIButton            alloc]initWithFrame:cg(0,1,1,1)];
#undef cg
    
    // Set properties
    [self.name_control setText:g_meter.p.cbPeripheral.name];
    [self.name_control setFont:[UIFont systemFontOfSize:24]];
    [self.name_control setTextColor:[UIColor lightGrayColor]];
    [self.name_control setTextAlignment:NSTextAlignmentCenter];
    [self.name_control addTarget:self action:@selector(nameSelected) forControlEvents:UIControlEventEditingDidBegin];
    [self.name_control addTarget:self action:@selector(nameDeselected) forControlEvents:UIControlEventEditingDidEnd];
    self.name_control.delegate = self;
    self.name_control.inputAccessoryView = name_apply_toolbar;
    /*
    [self.logging_period_control addTarget:self action:@selector(loggingPeriodSet) forControlEvents:UIControlEventValueChanged];
    for(int i = 0; i < [freq_options count]; i++) {
        if(g_meter->meter_log_settings.rw.logging_period_ms <= period_values[i]) {
            [self.logging_period_control setSelectedSegmentIndex:i];
            break;
        }
    }
    
    [self.logging_time_control setText:@"Logging Time (hours)"];
    [self.logging_time_control setFont:[UIFont systemFontOfSize:24]];
    [self.logging_time_control setTextColor:[UIColor lightGrayColor]];
    [self.logging_time_control setTextAlignment:NSTextAlignmentCenter];
    [self.logging_time_control addTarget:self action:@selector(loggingTimeSelected) forControlEvents:UIControlEventEditingDidBegin];
    [self.logging_time_control addTarget:self action:@selector(loggingTimeSet) forControlEvents:UIControlEventEditingDidEnd];
    self.logging_time_control.keyboardType = UIKeyboardTypeNumberPad;
    self.logging_time_control.delegate = self;
    self.logging_time_control.inputAccessoryView = loglen_apply_toolbar;
    */
    
    [self.hibernate_button addTarget:self action:@selector(hibernateSet) forControlEvents:UIControlEventTouchUpInside];
    [self.hibernate_button setTitle:@"Hibernate" forState:UIControlStateNormal];
    [self.hibernate_button.titleLabel setFont:[UIFont systemFontOfSize:30]];
    [self.hibernate_button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[self.hibernate_button layer] setBorderWidth:2];
    [[self.hibernate_button layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    
    // Add as subviews
    [self addSubview:self.name_control];
    //[self addSubview:self.logging_period_control];
    //[self addSubview:self.logging_time_control];
    [self addSubview:self.hibernate_button];
    
    [[self layer] setBorderWidth:5];
    [[self layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    return self;
}

// Control Callbacks


-(void)nameSelected {
    [self.name_control setText:@""];
    [self.name_control setTextColor:[UIColor blackColor]];
}

-(void)nameDeselected {
    [self.name_control setTextColor:[UIColor lightGrayColor]];
    NSString* new_name = self.name_control.text;
    NSLog(@"%@", new_name);
    if(new_name.length != 0) {
        new_name = [new_name substringToIndex: MIN(16, [new_name length])];
        [g_meter sendMeterName:new_name cb:^(NSError *error) {
            DLog(@"Name send complete");
        }];
    }
    [self.name_control resignFirstResponder];
}

-(void)nameCancel {
    [self.name_control resignFirstResponder];
}
/*
-(void)loggingPeriodSet {
    const uint16 period_values[] = {0, 1000, 10000, 60*1000};
    const uint16 period_ms = period_values[self.logging_period_control.selectedSegmentIndex];
    g_meter->meter_log_settings.rw.logging_period_ms = period_ms;
    // This cascades in to the number of samples we want to take
    [self loggingTimeSet];
}

-(void)loggingTimeSelected {
    [self.logging_time_control setText:@""];
    [self.logging_time_control setTextColor:[UIColor blackColor]];
}

-(void)loggingTimeSet {
    const int sample_freq = 125<<(g_meter->meter_settings.rw.adc_settings&ADC_SETTINGS_SAMPLERATE_MASK);
    const double new_time_hours = [self.logging_time_control.text doubleValue];
    const double sample_interval_ms = g_meter->meter_log_settings.rw.logging_period_ms + ([g_meter getBufLen]/sample_freq);
    const double new_time_ms = new_time_hours*60*60*1000;
    const int n_samples = new_time_ms/sample_interval_ms;
    g_meter->meter_log_settings.rw.logging_n_cycles = n_samples;
    [g_meter sendMeterLogSettings:^(NSError *error) {
        DLog(@"Log settings send");
    }];
    [self.logging_time_control resignFirstResponder];
}

-(void)loggingTimeSetCancel {
    [self.logging_time_control resignFirstResponder];
}
*/
-(void)hibernateSet {
    DLog(@"Entering hibernate!");
    UIAlertView* hibernate_confirm = [[UIAlertView alloc] initWithTitle:@"Confirm Hibernation" message:@"Once in hibernation, you will not be able to connect to the meter until you short out the Ω input to wake the meter up." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Hibernate", nil];
    [hibernate_confirm show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    DLog(@"Confirm");
    if(buttonIndex) {
        g_meter->meter_settings.rw.target_meter_state = METER_HIBERNATE;
        [g_meter sendMeterSettings:^(NSError *error) {
            DLog(@"Sent");
        }];
    }
}

// UITextFieldDelegate

-(BOOL)textFieldShouldEndEditting:(UITextField*)f {
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)f {
    [f resignFirstResponder];
    return NO;
}

@end
