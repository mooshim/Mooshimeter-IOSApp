//
//  mooshimeterAppDelegate.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "mooshimeter_device.h"

#import "mooshimeterScanViewController.h"

#import "BLETIOADProgressViewController.h"
#import "BLETIOADProfile.h"

@class mooshimeter_device;
@class mooshimeterScanViewController;
@class BLETIOADProgressViewController;
@class BLETIOADProfile;

#define AUTO_UPDATE_FIRMWARE


@interface mooshimeterAppDelegate : UIResponder <UIApplicationDelegate, CBCentralManagerDelegate, NSObject>
{
    @public
    bool reboot_into_oad;
}

@property (strong,nonatomic) UIWindow *window;
@property (strong,nonatomic) CBCentralManager *cman;
@property (strong,nonatomic) NSMutableArray *meters;
@property (strong,nonatomic) NSMutableArray *meter_rssi;
@property (strong,nonatomic) mooshimeter_device* active_meter;
@property (strong,nonatomic) BLETIOADProfile* oad_profile;

@property (strong,nonatomic) UINavigationController* nav;
@property (strong,nonatomic) mooshimeterScanViewController* scan_vc;
@property (strong,nonatomic) BLETIOADProgressViewController* oad_vc;

-(mooshimeterAppDelegate*)getApp;
-(UINavigationController*)getNav;
-(void)scanForMeters;
-(void)endScan;

-(void)selectPeripheral:(CBPeripheral*)p;

@end
