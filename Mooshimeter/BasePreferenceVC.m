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

#import "BasePreferenceVC.h"
#import "WidgetFactory.h"
#import "Prefman.h"


@implementation BasePreferenceVC {
}
const int row_h = 80;
const int title_h = 30;
const int inset = 10;
const int spacer_h = 5;
const int acc_inset = 10;

-(void)addSpacer {
    UIView* spacer = [[UIView alloc] init];
    [spacer setBackgroundColor:[UIColor lightGrayColor]];
    [spacer setLLSize:spacer_h];
    [_background_ll addSubview:spacer];
}

-(void)addCell:(UIView*)view {
    [view setLLSize:row_h];
    [_background_ll addSubview:view];
    [self addSpacer];
}

-(UIView*)addPreferenceCell:(NSString*)title msg:(NSString*)msg accessory:(UIView*)accessory {
    LinearLayout* rval = [[LinearLayout alloc] initWithDirection:LAYOUT_HORIZONTAL];
    [rval setLLSize:row_h];

    LinearLayout* leftpane = [[LinearLayout alloc] initWithDirection:LAYOUT_VERTICAL];
    [leftpane setLLWeight:1];

    UILabel* title_label = [[UILabel alloc] init];
    [title_label setLLSize:title_h];
    [title_label setText:title];
    [title_label setFont:[UIFont boldSystemFontOfSize:24]];

    UILabel* msg_label = [[UILabel alloc] init];
    [msg_label setLLSize:row_h-title_h];
    [msg_label setText:msg];
    [msg_label setFont:[UIFont systemFontOfSize:18]];
    [msg_label setNumberOfLines:0];

    [leftpane addSubview:title_label];
    [leftpane addSubview:msg_label];

    [rval addSubview:leftpane];

    if(accessory!=nil) {
        [accessory setLLSize:row_h];
        [accessory setLLInset:acc_inset];
        [rval addSubview:accessory];
    }

    // Center the accessory in the space available for it
    /*CGRect acc_frame = accessory.frame;
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

    [self.content_view addSubview:rval];*/
    [_background_ll addSubview:rval];

    [self addSpacer];

    return rval;
}

+(UISwitch*)makePrefSwitch:(NSString*)key {
    UISwitch * rval = [WidgetFactory makeSwitch:^(bool i) {
        [Prefman setPreference:key value:i];
    }];
    [rval setOn:[Prefman getPreference:key def:NO]];
    return rval;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _background_ll = [[LinearLayout alloc] initWithDirection:LAYOUT_VERTICAL];
    _background_ll.frame = CGRectInset(self.content_view.bounds,20,20);
    [self.content_view addSubview:_background_ll];
}

@end
