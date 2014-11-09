//
//  mooshimeterDetailViewController.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "MeterViewController.h"

@interface MeterViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation MeterViewController

#pragma mark - Managing the detail item

-(BOOL)prefersStatusBarHidden { return YES; }

-(MeterViewController*)init {
    self = [super init];
    self->play = NO;
    return self;
}

- (void)setDevice:(MooshimeterDevice*)device
{
    NSLog(@"I am in setDetailItem");
    BUILD_BUG_ON(sizeof(int24_test) != 3);
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
    NSLog(@"Detail view loaded!");
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    scroll.contentSize = CGSizeMake(320, 1500);
    scroll.showsHorizontalScrollIndicator = YES;
    
    int yoff = 0;
    UISegmentedControl *segmentedControl;
    NSArray *itemArray;
    UILabel *label;
    UITextField *textField;
    
    // Add Channel 2 (voltage channel) display
    self.Label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 100.0)];
    yoff+=100;
    self.Label1.textColor = [UIColor blackColor];
    self.Label1.font = [UIFont fontWithName:@"Courier New" size:70];
    self.Label1.text = @"0.00000";
    [scroll addSubview:self.Label1];

    // Add Channel 1 (current channel) display
    self.Label0 = [[UILabel alloc] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 100.0)];
    yoff+=100;
    self.Label0.textColor = [UIColor blackColor];
    self.Label0.font = [UIFont fontWithName:@"Courier New" size:70];
    self.Label0.text = @"0.00000";
    [scroll addSubview:self.Label0];
    
#if 0
    // Add Channel 1 setting control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Channel 1 Setting";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"Current", @"Temp.", @"Aux", @"Off", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(changeCH1Setting:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Add Channel 1 PGA control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Channel 1 PGA Gain";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"6", @"1", @"2", @"3", @"4", @"8", @"12", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.selectedSegmentIndex = 1;
    [segmentedControl addTarget:self action:@selector(changeCH1PGA:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Add Channel 2 setting control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Channel 2 Setting";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"±1.2V", @"±60V", @"±1kV", @"Temp.", @"Aux", @"Off", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.selectedSegmentIndex = 1;
    [segmentedControl addTarget:self action:@selector(changeCH2Setting:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Add Channel 2 PGA control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Channel 2 PGA Gain";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"6", @"1", @"2", @"3", @"4", @"8", @"12", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.selectedSegmentIndex = 1;
    [segmentedControl addTarget:self action:@selector(changeCH2PGA:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Add Channel 3 setting control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Current Source";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"Off", @"97n", @"97u", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(changeCurrentSourceSetting:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"100K Pulldown";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"OFF", @"ON", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(changePulldownSetting:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Sample Rate Control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Sample Rate (Hz)";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"125", @"250", @"500", @"1k", @"2k", @"4k", @"8k", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 3;
    [segmentedControl addTarget:self action:@selector(changeSampleRate:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Sample Rate Control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Buffer Depth";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"1", @"2", @"4", @"8", @"16", @"32", @"64", @"128", @"256", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 7;
    [segmentedControl addTarget:self action:@selector(changeBufferDepth:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Rename meter
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Set Name";
    [scroll addSubview:label];
    
    CGRect frame = CGRectMake(0, yoff, self.view.bounds.size.width, 30);
    yoff += 50;
    textField = [[UITextField alloc] initWithFrame:frame];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.textColor = [UIColor blackColor];
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.placeholder = @"MyMooshimeter";
    textField.backgroundColor = [UIColor whiteColor];
    textField.autocorrectionType = UITextAutocorrectionTypeYes;
    textField.keyboardType = UIKeyboardTypeDefault;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    //[textField addTarget:self action:@selector(changeName:) forControlEvents:UIControlEvent];
    [scroll addSubview:textField];
#endif
    [self.view addSubview:scroll];
    [self play];
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Detail View about to appear");
    }

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    self.meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_ONESHOT;
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
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

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(fromInterfaceOrientation == UIInterfaceOrientationPortrait || fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self.tabBarController setSelectedIndex:4];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) play {
    NSLog(@"In Play");
    if( ! self->play ) {
        [self.meter enableStreamMeterBuf:nil cb:nil arg:nil];
        [self.meter setBufferReceivedCallback:self cb:@selector(updateReadings) arg:nil];
        self.meter->meter_settings.rw.target_meter_state = METER_RUNNING;
        [self.meter sendMeterSettings:nil cb:nil arg:nil];
        self->play = YES;
    }
}

-(void) pause {
    self->play = NO;
    //[self.meter stopStreamMeterSample];
    [self.meter disableStreamMeterBuf];
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
    self.meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
    
    if(self.meter->disp_settings.ch1Off) {
        self.Label1.text = @"";
        self.CH1Label.text = @"";
    } else {
        // Quick and dirty hack to catch overload values for resistance
        // Since no other measurement will go in to the millions we can hack like this
        if( [self.meter getCH1BufAvg] > 5e6 ) {
            self.Label1.text = @"Overload";
        } else {
            //if( self.meter->ADC_settings.str.ch1set && 0x0F == 0x00 ) {
            self.Label1.text = [self formatReading:[self.meter getCH1BufAvg] resolution:1e-4 unit:[self.meter getCH1Units] ];
        }
        self.CH1Label.text = [self.meter getCH1Label];
    }
    
    if(self.meter->disp_settings.ch2Off) {
        self.Label0.text = @"";
        self.CH2Label.text = @"";
    } else {
        if( [self.meter getCH2Value] > 5e6 ) {
            self.Label0.text = @"Overload";
        } else {
            self.Label0.text = [self formatReading:[self.meter getCH2BufAvg] resolution:1e-5 unit:[self.meter getCH2Units] ];
        }
        self.CH2Label.text = [self.meter getCH2Label];
    }

    self.CH1Raw.text = [NSString stringWithFormat:@"%06X",[self.meter getBufAvg:self.meter->sample_buf.CH1_buf]];
    self.CH2Raw.text = [NSString stringWithFormat:@"%06X",[self.meter getBufAvg:self.meter->sample_buf.CH2_buf]];
    
    //[self performSelector:@selector(trig) withObject:nil afterDelay:1];
    self.meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

@end
