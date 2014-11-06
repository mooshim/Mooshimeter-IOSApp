//
//  ScanTableViewCell.h
//  Mooshimeter
//
//  Created by James Whong on 11/4/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class mooshimeter_device;

@interface ScanTableViewCell : UITableViewCell

@property (strong,nonatomic) CBPeripheral* p;

-(void) setPeripheral:(CBPeripheral*)device;
-(void) setRSSI:(NSNumber*)RSSI;

@end
