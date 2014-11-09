//
//  mooshimeterMasterViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "MooshimeterDevice.h"
#import "ScanTableViewCell.h"

@class MeterViewController;
@class AppDelegate;

@interface ScanViewController : UITableViewController <UIAlertViewDelegate>

@property (strong, nonatomic)MeterViewController *detailViewController;
@property (strong, nonatomic)AppDelegate *app;

-(void)reloadData;
-(void)endRefresh;

@end
