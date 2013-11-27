//
//  mooshimeterDetailViewController.m
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import "mooshimeterSettingViewController.h"

@interface mooshimeterSettingViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation mooshimeterSettingViewController

#pragma mark - Managing the detail item

- (void)setDevice:(mooshimeter_device*)device
{
    self.meter = device;
}

- (void)configureView
{
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    scroll.contentSize = CGSizeMake(320, 800);
    scroll.showsHorizontalScrollIndicator = YES;
    
    int yoff = 0;
    UISegmentedControl *segmentedControl;
    UIButton *button;
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
    
    itemArray = [NSArray arrayWithObjects: @"Current", @"Batt.", @"Temp.", @"Aux", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(changeCH1Setting:) forControlEvents:UIControlEventValueChanged];
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
    
    itemArray = [NSArray arrayWithObjects: @"±60V", @"±1kV", @"Batt.", @"Temp.", @"Aux", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(changeCH2Setting:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:segmentedControl];
    
    // Add Channel 3 setting control
    label = [ [UILabel alloc ] initWithFrame:CGRectMake(0, yoff, self.view.bounds.size.width, 50.0) ];
    yoff += 50;
    label.textAlignment =  NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Helvetica" size:(30.0)];
    label.text = @"Aux. Setting";
    [scroll addSubview:label];
    
    itemArray = [NSArray arrayWithObjects: @"Prec. V", @"Ω", @"Diode", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(changeCH3Setting:) forControlEvents:UIControlEventValueChanged];
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
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(onCalButtonPressed)
     forControlEvents:UIControlEventTouchDown];
    [button setTitle:@"Re-Zero Now" forState:UIControlStateNormal];
    button.frame = CGRectMake(0, yoff, self.view.bounds.size.width, 50);
    yoff += 60;
    [scroll addSubview:button];
    
    [self.view addSubview:scroll];
}

#define SET_W_MASK(target, val, mask) target ^= (mask)&((val)^target)

-(void) changeSampleRate:(id)sender {
    NSLog(@"Rate");
    UISegmentedControl* source = sender;
    
    SET_W_MASK( self.meter->ADC_settings.str.config1, source.selectedSegmentIndex, 0X07);
    [self.meter sendADCSettings:nil cb:nil arg:nil];
}

- (void)onCalButtonPressed
{
    NSLog(@"Running a cal");
    [self.meter doCal:nil cb:nil arg:nil];
    [self performSelector:@selector(saveCalToIndex4) withObject:nil afterDelay:5.0];
}

-(void)saveCalToIndex4 {
    NSLog(@"Saving to NV");
    [self.meter saveCalToNV:4 target:nil cb:nil arg:nil];
}

-(void) changeCH1Setting:(id)sender {
    NSLog(@"CH1");
    UISegmentedControl* source = sender;
    const char state_machine[] = { 0x00, 0x03, 0x04, 0x09 };
    
    SET_W_MASK( self.meter->ADC_settings.str.ch1set, state_machine[source.selectedSegmentIndex], 0X0F);
    [self.meter sendADCSettings:nil cb:nil arg:nil];    
}

-(void) changeCH2Setting:(id)sender {
    NSLog(@"CH2");
    UISegmentedControl* source = sender;
    const char ch2_set_states[]  = { 0x00, 0x00, 0x03, 0x04, 0x09 };
    const char gpio_set_states[] = { 0x00, 0x02, 0x00, 0x00, 0x00 };

    SET_W_MASK( self.meter->ADC_settings.str.ch2set, ch2_set_states[ source.selectedSegmentIndex], 0X0F);
    SET_W_MASK( self.meter->ADC_settings.str.gpio  , gpio_set_states[source.selectedSegmentIndex], 0X042);
    [self.meter sendADCSettings:nil cb:nil arg:nil];
}

-(void) changeCH3Setting:(id)sender {
    NSLog(@"CH3");
    UISegmentedControl* source = sender;
    const char gpio_states[] = { 0x00, 0x01, 0x01 };
    
    self.meter->disp_settings.ch3_mode = source.selectedSegmentIndex;
    
    SET_W_MASK( self.meter->ADC_settings.str.gpio, gpio_states[source.selectedSegmentIndex], 0X01);
    [self.meter sendADCSettings:nil cb:nil arg:nil];
}

-(void) setGraphMode:(id)sender {
    NSLog(@"SetGraphMode");
    UISegmentedControl* source = sender;
    self.meter->disp_settings.xy_mode = source.selectedSegmentIndex?YES:NO;
}

#undef SET_W_MASK

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
