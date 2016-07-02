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
#import "BLEUtility.h"
#import "LegacyMooshimeterDevice.h"
#import "ChannelView.h"
#import "BaseVC.h"
#import "SpeaksOnLargeChange.h"

@class ChannelView;

@interface MeterVC : BaseVC <MooshimeterDelegateProtocol>

// Housekeeping
@property MooshimeterDeviceBase * meter;

@property SpeaksOnLargeChange* speaker;

// GUI widgets

@property (strong, nonatomic) ChannelView* ch1_view;
@property (strong, nonatomic) ChannelView* ch2_view;

@property (strong,nonatomic) UILabel*  math_label;
@property (strong,nonatomic) UIButton*  math_button;

@property (strong, nonatomic) UIButton* rate_button;
@property (strong, nonatomic) UIButton* depth_button;
@property (strong, nonatomic) UIButton* logging_button;
@property (strong, nonatomic) UIButton* graph_button;

@property UIImageView* bat_icon;
@property UIImageView* sig_icon;

//@property (strong, nonatomic) MeterSettingsView* settings_view;

-(instancetype)initWithMeter:(MooshimeterDeviceBase *)meter;

@end
