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

@interface SettingViewController : UIViewController

-(void)setDevice:(MooshimeterDevice*)device;

@property (strong, nonatomic) MooshimeterDevice *meter;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;


@property (strong, nonatomic) IBOutlet UIButton *CalButton;
@property (strong, nonatomic) IBOutlet UIButton *CH1Button;
@property (strong, nonatomic) IBOutlet UIButton *CH2Button;
@property (strong, nonatomic) IBOutlet UIButton *RateButton;
@property (strong, nonatomic) IBOutlet UIButton *NameButton;

@end
