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

#import <UIKit/UIKit.h>
#import "MooshimeterDevice.h"

@interface MeterSettingsView : UIView <UITextFieldDelegate,UIAlertViewDelegate>

@property (strong,nonatomic) UITextField*           name_control;
@property (strong,nonatomic) UISegmentedControl*    logging_period_control;
//@property (strong,nonatomic) UITextField*           logging_time_control;
@property (strong,nonatomic) UIButton*              hibernate_button;
@property (strong,nonatomic) UIButton*              force_rotation_button;

@end
