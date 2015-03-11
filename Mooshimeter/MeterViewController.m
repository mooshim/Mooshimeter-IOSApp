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
    
    self.ch1_view = [[ChannelView alloc]initWithFrame:cg(0, 0, 6, 4) ch:0];
    [v addSubview:self.ch1_view];
    
    self.ch2_view = [[ChannelView alloc]initWithFrame:cg(0, 4, 6, 4) ch:1];
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
    logging_state_t* s = &g_meter->meter_log_settings.rw.target_logging_state;
    switch(*s) {
        case LOGGING_OFF:
            *s = LOGGING_SAMPLING;
            break;
        case LOGGING_SAMPLING:
            *s = LOGGING_OFF;
            break;
        default:
            *s = LOGGING_OFF;
            break;
    }
    [g_meter sendMeterLogSettings:^(NSError *error) {
        [g_meter performSelector:@selector(reqMeterLogSettings:) withObject:^(NSData *data, NSError *error) {
            [self refreshAllControls];
        } afterDelay:1.0];
    }];
}
-(void)logging_button_refresh {
    logging_state_t* s = &g_meter->meter_log_settings.rw.target_logging_state;
    switch(*s) {
        case LOGGING_OFF:
            [self.logging_button setTitle:@"Logging:OFF" forState:UIControlStateNormal];
            [self.logging_button setBackgroundColor:[UIColor redColor]];
            break;
        case LOGGING_SAMPLING:
            [self.logging_button setTitle:@"Logging:ON" forState:UIControlStateNormal];
            [self.logging_button setBackgroundColor:[UIColor greenColor]];
            break;
        default:
            [self.logging_button setBackgroundColor:[UIColor lightGrayColor]];
            break;
    }
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
        depth_setting %= 9;
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

-(void)settings_button_press {
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
    }
}

-(void)zero_button_press {
    g_meter->offset_on ^= YES;
    if(g_meter->offset_on) {
        [g_meter setZero];
    } else {
        [g_meter clearOffsets];
    }
    [self refreshAllControls];
}

-(void)settings_button_refresh {
    DLog(@"Disp");
    //[self.settings_button setBackgroundColor:[UIColor lightGrayColor]];
}

-(void)zero_button_refresh {
    if(g_meter->offset_on) {
        [self.zero_button setBackgroundColor: [UIColor greenColor]];
    } else {
        [self.zero_button setBackgroundColor: [UIColor redColor]];
    }
}

-(void) refreshAllControls {
    // Make all controls reflect the state of the meter
    [self rate_auto_button_refresh];
    [self rate_button_refresh];
    [self depth_auto_button_refresh];
    [self depth_button_refresh];
    [self logging_button_refresh];
    [self zero_button_refresh];
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
    g_meter->meter_settings.rw.target_meter_state = METER_PAUSED;
    // Preserve the depth setting, overwrite other calc settings
    g_meter->meter_settings.rw.calc_settings &= METER_CALC_SETTINGS_DEPTH_LOG2;
    g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_MS|METER_CALC_SETTINGS_MEAN;
    
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
        [self.delegate switchToGraphView];
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
    if(!g_meter) return;
    g_meter->meter_settings.rw.target_meter_state = METER_PAUSED;
    [g_meter sendMeterSettings:^(NSError *error) {
        NSLog(@"Paused!");
    }];
}

+(NSString*) formatReading:(double)val digits:(SignificantDigits)digits {
    //TODO: Unify prefix handling.  Right now assume that in the area handling the units the correct prefix
    // is being applied
    while(digits.high > 4) {
        digits.high -= 3;
        val /= 1000;
    }
    while(digits.high <=0) {
        digits.high += 3;
        val *= 1000;
    }
    
    // TODO: Prefixes for units.  This will fail for wrong values of digits
    BOOL neg = val<0;
    int left = digits.high;
    int right = -1*(digits.high-digits.n_digits);
    NSString* formatstring = [NSString stringWithFormat:@"%@%%0%d.%df", neg?@"":@" ", (left+right+neg)?0:1, right];  // To live is to suffer
    NSString* retval = [NSString stringWithFormat:formatstring, val];
    //Truncate
    retval = [retval substringWithRange:NSMakeRange(0, MIN(retval.length,8))];
    return retval;
}

-(void) updateReadings {
    NSLog(@"Updating measurements...");
    [self.ch1_view value_label_refresh];
    [self.ch2_view value_label_refresh];
    
    // Handle autoranging
    // Save a local copy of settings
    MeterSettings_t save = g_meter->meter_settings;
    [g_meter applyAutorange];
    // Check if anything changed, and if so apply changes
    if(memcmp(&save, &g_meter->meter_settings, sizeof(MeterSettings_t))) {
        [g_meter sendMeterSettings:^(NSError *error) {
            [self refreshAllControls];
        }];
    }
}

@end
