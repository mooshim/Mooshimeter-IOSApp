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

#import "ScanVC.h"

#import "BLETIOADProgressViewController.h"
#import "BLETIOADProfile.h"

@class MooshimeterDevice;
@class ScanViewController;
@class BLETIOADProgressViewController;

#define AUTO_UPDATE_FIRMWARE


@interface mooshimeterAppDelegate : UIResponder <UIApplicationDelegate, CBCentralManagerDelegate, NSObject>
{
    @public
    bool reboot_into_oad;
}

@property (strong,nonatomic) UIWindow *window;
@property (strong,nonatomic) CBCentralManager *cman;

@property (strong,nonatomic) UINavigationController* nav;
@property (strong,nonatomic) ScanViewController* scan_vc;
@property (strong,nonatomic) BLETIOADProgressViewController* oad_vc;

-(mooshimeterAppDelegate*)getApp;
-(UINavigationController*)getNav;
-(void)scanForMeters;
-(void)endScan;

-(void)selectMeter:(MooshimeterDevice*)p;

@end
