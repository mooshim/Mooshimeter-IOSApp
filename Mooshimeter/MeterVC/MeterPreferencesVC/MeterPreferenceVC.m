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

#import "MeterPreferenceVC.h"
#import "WidgetFactory.h"
#import "PopupMenu.h"

@implementation MeterPreferenceVC {
}

////////////////////
// Lifecycle methods
////////////////////

-(instancetype)initWithMeter:(MooshimeterDeviceBase *)meter{
    self = [super init];
    self.meter = meter;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:@"Meter Preferences"];

    // Meter Name
    [self addPreferenceCell:@"Name" msg:@"Set the device name" accessory:[WidgetFactory makeButton:@"Set" callback:^{
            // Start a dialog box to get some input
        [WidgetFactory makeTextInputBox:@"Enter New Name" msg:@"18 character max" callback:^(NSString *string) {
            NSLog(@"Received %@",string);
            if([string length]>18) {
                return;
            }
            [self.meter setName:string];
        }];
    } frame:CGRectMake(0,0,50,50)]];

    // Logging interval
    {
        NSString* title = [NSString stringWithFormat:@"%ds",([self.meter getLoggingIntervalMS]/1000)];
        UIButton* b = [WidgetFactory makeButtonReflexive:title callback:^(UIButton *button) {
            // Start a dialog box to get some input
            NSArray<NSString*>* s_options = @[@"MAX",@"1s",@"10s",@"1min"];
            NSArray<NSNumber*>* i_options = @[@0,@1000,@(10*1000),@(60*1000)];
            [PopupMenu displayOptionsWithParent:self.view
                                          title:@"Logging Interval"
                                        options:s_options callback:^(int i) {
                        [self.meter setLoggingInterval:[i_options[i] integerValue]];
                        [button setTitle:[NSString stringWithFormat:@"%ds", ([self.meter getLoggingIntervalMS] / 1000)] forState:UIControlStateNormal];
                    }];
        }];
        [b setFrame:CGRectMake(0,0,50,50)];
        [self addPreferenceCell:@"Logging Interval" msg:@"Set the time between samples when logging is on." accessory:b];
    }

    // Shipping mode
    [self addPreferenceCell:@"Shipping Mode" msg:@"Turn off the radio for shipping." accessory:[WidgetFactory makeButton:@"Set" callback:^{
        // Start a dialog box to get some input
        [WidgetFactory makeYesNoAlert:@"Enter shipping mode?"
                                  msg:@"This will turn off the radio.  You will need to connect the C and Ω terminals to turn the radio back on."
                             callback:^(bool proceed) {
                                 if (!proceed) {return;}
                                 [self.meter enterShippingMode];
                             }];
    } frame:CGRectMake(0,0,50,50)]];

    // Shipping mode
    [self addPreferenceCell:@"Reboot" msg:@"Reboots the meter immediately." accessory:[WidgetFactory makeButton:@"Set" callback:^{
        // Start a dialog box to get some input
        [self.meter reboot];
    } frame:CGRectMake(0,0,50,50)]];

    // Autoconnect
    [self addPreferenceCell:@"Autoconnect" msg:@"Connect immediately when device appears in scan." accessory:[MeterPreferenceVC makePrefSwitch:[self.meter getPreferenceKeyString:@"AUTOCONNECT"]]];
    // Skip upgrade
    [self addPreferenceCell:@"Skip Upgrade" msg:@"Skip firmware upgrade prompt." accessory:[MeterPreferenceVC makePrefSwitch:[self.meter getPreferenceKeyString:@"SKIP_UPGRADE"]]];
}

@end
