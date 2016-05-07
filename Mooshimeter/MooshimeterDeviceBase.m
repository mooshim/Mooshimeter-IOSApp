//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MooshimeterDeviceBase.h"
#import "LGBluetooth.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEUtility.h"
#import "LegacyMooshimeterDevice.h"


@implementation MooshimeterDeviceBase

- (bool *)speech_on {return _speech_on;}
- (bool *)range_auto {return _range_auto;}

#pragma mark MooshimeterControlProtocol_methods
-(void)addDelegate:(id<MooshimeterDelegateProtocol>)d {
    self.delegate = d;
}
-(void)removeDelegate {
    self.delegate = NULL;
}
+(uint32)getBuildTimeFromPeripheral:(LGPeripheral *)periph {
    uint32 rval = 0;
    NSData* tmp;
    tmp = [periph.advertisingData valueForKey:@"kCBAdvDataManufacturerData"];
    if( tmp == nil ) {
        return 0xFFFFFFFF;
    }
    [tmp getBytes:&rval length:4];
    return rval;
}
+(bool)isPeripheralInOADMode:(LGPeripheral *)periph {
    // PERIPHERAL MUST BE CONNECTED AND DISCOVERED
    for(LGService* service in periph.services) {
        if([service.UUIDString isEqualToString:[BLEUtility expandToMooshimUUIDString:OAD_SERVICE_UUID]]) {
            return true;
        }
    }
    return false;
}
+(MooshimeterDeviceBase *)chooseSubClass:(LGPeripheral *)connected_peripheral {
    if(connected_peripheral.cbPeripheral.state != CBPeripheralStateConnected) {
        NSLog(@"Can't decide subclass until after connection!");
        return nil;
    }
    Class rval = nil;
    if([self isPeripheralInOADMode:connected_peripheral]) {
        NSLog(@"Wrapping as an OADDevice (LegacyMeter)");
        rval = [LegacyMooshimeterDevice class];
        //rval = [[LegacyMooshimeterDevice alloc] init:connected_peripheral delegate:nil];
    } else if([self getBuildTimeFromPeripheral:connected_peripheral] < 1454355414) {
        NSLog(@"Wrapping as a LegacyMeter");
        rval = [LegacyMooshimeterDevice class];
        //rval = [[LegacyMooshimeterDevice alloc] init:connected_peripheral delegate:nil];
    } else {
        rval = nil;
        //fixme
        //IMPLEMENT ME - NEW STYLE MOOSHIMETERDEVICE
    }
    return rval;
}
@end