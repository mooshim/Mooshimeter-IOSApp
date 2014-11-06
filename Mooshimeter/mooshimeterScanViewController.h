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
#import "ScanTableViewCell.h"

@class mooshimeterMeterViewController;
@class mooshimeterAppDelegate;

@interface mooshimeterScanViewController : UITableViewController <UIAlertViewDelegate>

@property (strong, nonatomic)mooshimeterMeterViewController *detailViewController;
@property (strong, nonatomic)mooshimeterAppDelegate *app;

-(void)reloadData;
-(void)endRefresh;

@end
