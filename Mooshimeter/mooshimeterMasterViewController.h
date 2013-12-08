//
//  mooshimeterMasterViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "mooshimeter_device.h"
#import "mooshimeterTabBarController.h"

@class mooshimeterDetailViewController;

@interface mooshimeterMasterViewController : UITableViewController <CBCentralManagerDelegate,CBPeripheralDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) mooshimeterDetailViewController *detailViewController;
@property (strong, nonatomic) mooshimeter_device *meter;
@property (strong, nonatomic) NSMutableArray *n_meters;
@property (strong, nonatomic) NSMutableArray *meters;
@property (strong, nonatomic) CBCentralManager *ble_master;
@property (strong, nonatomic) NSMutableArray *meter_rssi;


@property (nonatomic, retain) UILabel *openingMessage1;
@property (nonatomic, retain) UILabel *openingMessage2;
@property (strong, nonatomic) UIAlertView *megaAlert;

@end
