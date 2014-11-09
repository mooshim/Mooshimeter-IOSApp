//
//  ScanTableViewCell.h
//  Mooshimeter
//
//  Created by James Whong on 11/4/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "MooshimeterDevice.h"

@class MooshimeterDevice;

@interface ScanTableViewCell : UITableViewCell

@property (strong,nonatomic) MooshimeterDevice* d;


-(void) setMeter:(MooshimeterDevice*)device;

@end
