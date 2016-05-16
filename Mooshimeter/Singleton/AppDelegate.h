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
#import <CoreBluetooth/CoreBluetooth.h>
#import "LegacyMooshimeterDevice.h"
#import "LGBluetooth.h"

#import "ScanVC.h"
#import "MeterVC.h"
#import "../GraphVC.h"
#import "SmartNavigationController.h"

#import "OADProgressViewController.h"
#import "OADProfile.h"

@class SmartNavigationController;
@class ScanVC;
@class OADProfile;
@class OADViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSObject>

@property (strong,nonatomic) UIWindow *window;

@property (strong,nonatomic) SmartNavigationController*      nav;
@property (strong,nonatomic) ScanVC*             scan_vc;

@property (strong,nonatomic) UILabel* bat_label;
@property (strong,nonatomic) UILabel* rssi_label;
@property (strong,nonatomic) UIButton* settings_button;

@end
