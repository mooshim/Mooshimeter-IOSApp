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
#import "Prefman.h"

@implementation MeterPreferenceVC {
    float y_offset;
}

////////////////////
// Helper methods
////////////////////

-(UIView*)addPreferenceCell:(NSString*)title msg:(NSString*)msg accessory:(UIView*)accessory {
    const int row_h = 80;
    const int title_h = 30;
    const int inset = 10;
    const int spacer_h = 5;

    UIView* rval = [[UIView alloc] initWithFrame:CGRectMake(0,y_offset,self.visible_w,row_h)];
    y_offset += row_h;

    float left_w = .75*self.visible_w;

    UILabel* title_label = [[UILabel alloc] initWithFrame:CGRectMake(inset,0,left_w,title_h)];
    [title_label setText:title];
    [title_label setFont:[UIFont boldSystemFontOfSize:24]];

    UILabel* msg_label = [[UILabel alloc] initWithFrame:CGRectMake(inset,title_h,left_w,row_h-title_h)];
    [msg_label setText:msg];
    [msg_label setFont:[UIFont systemFontOfSize:18]];
    [msg_label setNumberOfLines:0];

    // Center the accessory in the space available for it
    CGRect acc_frame = accessory.frame;
    {
        float acc_w = self.visible_w-left_w-inset;
        float acc_x_inset = (acc_w - acc_frame.size.width)/2;
        float acc_y_inset = (row_h - acc_frame.size.height)/2;
        acc_frame.origin.x = left_w + acc_x_inset;
        acc_frame.origin.y = acc_y_inset;
    }
    [accessory setFrame:acc_frame];

    [rval addSubview:title_label];
    [rval addSubview:msg_label];
    [rval addSubview:accessory];

    [self.content_view addSubview:rval];

    UIView* spacer = [[UIView alloc] initWithFrame:CGRectMake(0,y_offset,self.visible_w,spacer_h)];
    y_offset+=spacer_h;
    [spacer setBackgroundColor:[UIColor lightGrayColor]];
    [self.content_view addSubview:spacer];

    return rval;
}

+(UISwitch*)makePrefSwitch:(NSString*)key {
    UISwitch * rval = [WidgetFactory makeSwitch:^(bool i) {
        [Prefman setPreference:key value:i];
    }];
    [rval setOn:[Prefman  getPreference:key def:NO]]; // FIXME! THIS IS REPEATED CODE WITH GLOBALPREFERENCEVC
    return rval;
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
    y_offset = 0;

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
        [WidgetFactory makeCancelContinueAlert:@"Enter shipping mode?"
                                           msg:@"This will turn off the radio.  You will need to connect the C and Ω terminals to turn the radio back on."
                                      callback:^(bool proceed) {
                                          if(!proceed){return;}
                                          [self.meter enterShippingMode];
                                      }];
    } frame:CGRectMake(0,0,50,50)]];

    // Autoconnect
    [self addPreferenceCell:@"Autoconnect" msg:@"Connect immediately when device appears in scan." accessory:[MeterPreferenceVC makePrefSwitch:[self.meter getPreferenceKeyString:@"AUTOCONNECT"]]];
    // Skip upgrade
    [self addPreferenceCell:@"Skip Upgrade" msg:@"Skip firmware upgrade prompt." accessory:[MeterPreferenceVC makePrefSwitch:[self.meter getPreferenceKeyString:@"SKIP_UPGRADE"]]];
}

@end
