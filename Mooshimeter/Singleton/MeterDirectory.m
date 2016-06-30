//
// Created by James Whong on 4/25/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MeterDirectory.h"

@implementation MeterDirectory
#pragma mark Singleton Methods

static MeterDirectory *shared = nil;

+ (instancetype)getSharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init {
    if(shared != nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"init for this singleton should not be called more than once!"
                                     userInfo:nil];
    } else {
        self.meter_dict = [[NSMutableDictionary alloc]init];
    }
    return self;
}

+(MooshimeterDeviceBase *)getMeterForUUID:(NSString*)uuid {
    return [MeterDirectory getSharedInstance].meter_dict[uuid];
}
+(void)addMeter:(MooshimeterDeviceBase *)meter {
    [MeterDirectory getSharedInstance].meter_dict[meter.periph.UUIDString] = meter;
}
+(void)removeMeter:(MooshimeterDeviceBase *)meter {
    [[MeterDirectory getSharedInstance].meter_dict removeObjectForKey:meter.periph.UUIDString];
}
+(MooshimeterDeviceBase *)getMeterForPeripheral:(LGPeripheral *)periph {
    return [self getMeterForUUID:periph.UUIDString];
}

@end