//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MooshimeterDeviceBase.h"
#import "LGBluetooth.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEUtility.h"
#import "LegacyMooshimeterDevice.h"
#import "OADDevice.h"


@interface DummyDelegate:NSObject <MooshimeterDelegateProtocol>
@end
@implementation DummyDelegate
- (void)onInit {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onDisconnect {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onRssiReceived:(int)rssi {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onBatteryVoltageReceived:(float)voltage {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading *)val {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber *> *)val {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onSampleRateChanged:(int)sample_rate_hz {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onBufferDepthChanged:(int)buffer_depth {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onLoggingStatusChanged:(bool)on new_state:(int)new_state message:(NSString *)message {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {NSLog(@"DUMMYDELEGATE CALL");}
@end

@implementation MooshimeterDeviceBase

- (bool *)speech_on {return _speech_on;}
- (bool *)range_auto {return _range_auto;}

-(instancetype)init {
    self = [super init];
    _speech_on[0] = NO;
    _speech_on[1] = NO;
    _speech_on[2] = NO;
    _range_auto[0] = NO;
    _range_auto[1] = NO;
    return self;
}

#pragma mark MooshimeterControlProtocol_methods
-(void)removeDelegate {
    self.delegate = [[DummyDelegate alloc]init];
}

-(NSString*)getPreferenceKeyString:(NSString*)tail {
    NSMutableString* rval = [NSMutableString stringWithString:@"mooshimeter-"];
    [rval appendString:self.periph.UUIDString];
    [rval appendString:@"-"];
    [rval appendString:tail];
    return rval;
}

-(bool)getPreference:(NSString*)shortkey {
    return [self getPreference:shortkey def:false];
}
-(bool)getPreference:(NSString*)shortkey def:(bool)def {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[self getPreferenceKeyString:shortkey]];
}

-(void)setPreference:(NSString*)shortkey value:(bool)value{
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:[self getPreferenceKeyString:shortkey]];
}

#pragma mark class methods

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
        NSLog(@"Wrapping as an OADDevice");
        rval = [OADDevice class];
    } else if([self getBuildTimeFromPeripheral:connected_peripheral] < 1454355414) {
        NSLog(@"Wrapping as a LegacyMeter");
        rval = [LegacyMooshimeterDevice class];
    } else {
        rval = nil;
        //fixme
        //IMPLEMENT ME - NEW STYLE MOOSHIMETERDEVICE
    }
    return rval;
}

#pragma mark MooshimeterControlProtocol_methods

-(bool)isInOADMode {
    return [MooshimeterDeviceBase isPeripheralInOADMode:self.periph];
}

@end