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

#import "SettingViewController.h"

@interface SettingViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation SettingViewController

#pragma mark - Managing the detail item

- (void)setDevice:(MooshimeterDevice*)device
{
    self.meter = device;
}

-(BOOL)prefersStatusBarHidden { return YES; }

- (void)configureView
{
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    scroll.contentSize = CGSizeMake(320, 1500);
    scroll.showsHorizontalScrollIndicator = YES;
    
    int yoff = 0;
    UISegmentedControl *segmentedControl;
    NSArray *itemArray;
    UILabel *label;
    UITextField *textField;
    
    // Add Channel 1 setting control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
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
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
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
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
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
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
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
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
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
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
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
    
    // Set XY Mode
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Graphing Mode";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"T-Y", @"X-Y", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(setGraphMode:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Run a calibration
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Calibration";
    [scroll addSubview:label];
    
    [self.view addSubview:scroll];
}



-(void) changeSampleRate:(id)sender {
    NSLog(@"Rate");
    UISegmentedControl* source = sender;
    
    SET_W_MASK( self.meter->meter_settings.rw.adc_settings, source.selectedSegmentIndex, 0x07);
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) changeBufferDepth:(id)sender {
    NSLog(@"Rate");
    UISegmentedControl* source = sender;
    
    SET_W_MASK( self.meter->meter_settings.rw.calc_settings, source.selectedSegmentIndex, METER_CALC_SETTINGS_DEPTH_LOG2);
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) changeCH1Setting:(id)sender {
    NSLog(@"CH1");
    UISegmentedControl* source = sender;
    const char state_machine[] = { 0x00, 0x04, 0x09 };
    
    if(source.selectedSegmentIndex == 4) {
        self.meter->disp_settings.ch1Off = YES;
    } else {
        self.meter->disp_settings.ch1Off = NO;
        SET_W_MASK( self.meter->meter_settings.rw.ch1set, state_machine[source.selectedSegmentIndex], 0X0F);
        [self.meter sendMeterSettings:nil cb:nil arg:nil];
    }
}

-(void) changeCH1PGA:(id)sender {
    NSLog(@"CH1PGA");
    UISegmentedControl* source = sender;
    
    SET_W_MASK( self.meter->meter_settings.rw.ch1set, source.selectedSegmentIndex<<4, 0XF0);
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) changeCH2Setting:(id)sender {
    NSLog(@"CH2");
    UISegmentedControl* source = sender;
    const char ch2_set_states[]  = { 0x00, 0x00, 0x00, 0x04, 0x09 };
    const char gpio_set_states[] = { 0x00, 0x01, 0x02, 0x00, 0x00 };

    if(source.selectedSegmentIndex == 6) {
        self.meter->disp_settings.ch2Off = YES;
    } else {
        self.meter->disp_settings.ch2Off = NO;
        SET_W_MASK( self.meter->meter_settings.rw.ch2set, ch2_set_states[ source.selectedSegmentIndex], 0X0F);
        SET_W_MASK( self.meter->meter_settings.rw.adc_settings  , gpio_set_states[source.selectedSegmentIndex]<<4, 0X30);
        [self.meter sendMeterSettings:nil cb:nil arg:nil];
    }
}

-(void) changeCH2PGA:(id)sender {
    NSLog(@"CH2PGA");
    UISegmentedControl* source = sender;
    
    SET_W_MASK( self.meter->meter_settings.rw.ch2set, source.selectedSegmentIndex<<4, 0XF0);
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) changeCurrentSourceSetting:(id)sender {
    NSLog(@"Current");
    UISegmentedControl* source = sender;
    
    switch( source.selectedSegmentIndex ) {
        case 0:
            self.meter->meter_settings.rw.measure_settings &= ~METER_MEASURE_SETTINGS_ISRC_LVL;
            self.meter->meter_settings.rw.measure_settings &= ~METER_MEASURE_SETTINGS_ISRC_ON;
            break;
        case 1:
            self.meter->meter_settings.rw.measure_settings &= ~METER_MEASURE_SETTINGS_ISRC_LVL;
            self.meter->meter_settings.rw.measure_settings |=  METER_MEASURE_SETTINGS_ISRC_ON;
            break;
        case 2:
            self.meter->meter_settings.rw.measure_settings |=  METER_MEASURE_SETTINGS_ISRC_LVL;
            self.meter->meter_settings.rw.measure_settings |=  METER_MEASURE_SETTINGS_ISRC_ON;
            break;
    }
    
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) changePulldownSetting:(id)sender {
    NSLog(@"Pulldown");
    UISegmentedControl* source = sender;
    
    switch( source.selectedSegmentIndex ) {
        case 0:
            self.meter->meter_settings.rw.measure_settings &= ~METER_MEASURE_SETTINGS_ACTIVE_PULLDOWN;
            break;
        case 1:
            self.meter->meter_settings.rw.measure_settings |=  METER_MEASURE_SETTINGS_ACTIVE_PULLDOWN;
            break;
    }
    
    [self.meter sendMeterSettings:nil cb:nil arg:nil];
}

-(void) setGraphMode:(id)sender {
    NSLog(@"SetGraphMode");
    UISegmentedControl* source = sender;
    self.meter->disp_settings.xy_mode = source.selectedSegmentIndex?YES:NO;
}

-(void) onNameButtonPressed {
    NSLog(@"Name");
}

- (void)viewDidLoad
{
    NSLog(@"Detail view trying to display!");
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
