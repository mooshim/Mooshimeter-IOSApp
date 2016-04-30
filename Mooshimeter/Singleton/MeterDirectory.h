//
// Created by James Whong on 4/25/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGPeripheral.h"
#import "MooshimeterDeviceBase.h"


@interface MeterDirectory : NSObject
// The NSString* key is the peripheral UUID
@property NSMutableDictionary<NSString*, MooshimeterDeviceBase*>* meter_dict;

+(instancetype)getSharedInstance;
+(MooshimeterDeviceBase *)getMeterForUUID:(NSString*)uuid;
+(void)addMeter:(MooshimeterDeviceBase *)meter;
+(void)removeMeter:(MooshimeterDeviceBase *)meter;
+(MooshimeterDeviceBase *)getMeterForPeripheral:(LGPeripheral *)periph;
@end