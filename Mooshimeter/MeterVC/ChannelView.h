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
#import "LegacyMooshimeterDevice.h"
#import "MeterVC.h"

@interface ChannelView : UIView

-(instancetype)initWithFrame:(CGRect)frame ch:(NSInteger)ch  meter:(MooshimeterDeviceBase *)meter;
-(void)value_label_refresh:(MeterReading*)value;
-(void)range_button_refresh;
-(void)display_set_button_refresh;
-(void)zero_button_refresh;

-(void)refreshAllControls;

@property Channel channel;
@property MooshimeterDeviceBase * meter;

@property (strong,nonatomic) UILabel*  value_label;
@property (strong,nonatomic) UIButton* display_set_button;
@property (strong,nonatomic) UIButton* range_button;
@property (strong,nonatomic) UIButton* zero_button;
@property (strong,nonatomic) UIButton* sound_button;

@end
