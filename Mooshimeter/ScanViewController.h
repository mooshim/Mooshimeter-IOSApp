//
//  mooshimeterMasterViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "LGPeripheral.h"
#import "MooshimeterDevice.h"
#import "ScanTableViewCell.h"

@protocol ScanViewControllerDelegate <NSObject>
@required
-(void)handleScanViewRefreshRequest;
-(void)handleScanViewSelect:(LGPeripheral*)p;
@end

@interface ScanViewController : UITableViewController <UIAlertViewDelegate>

@property (strong,nonatomic) id<ScanViewControllerDelegate> delegate;
@property (strong,nonatomic) NSArray* peripherals;

-(instancetype)initWithDelegate:(id)d;
-(void)reloadData;

@end
