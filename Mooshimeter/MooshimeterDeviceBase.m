//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MooshimeterDeviceBase.h"
#import "LGBluetooth.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEUtility.h"
#import "LegacyMooshimeterDevice.h"
#import "MooshimeterDevice.h"
#import "OADDevice.h"
#import "Prefman.h"


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
- (void)onLoggingStatusChanged:(BOOL)on new_state:(int)new_state message:(NSString *)message {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {NSLog(@"DUMMYDELEGATE CALL");}
- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {NSLog(@"DUMMYDELEGATE CALL");}
@end

@implementation MooshimeterDeviceBase

- (BOOL *)speech_on {return _speech_on;}
- (BOOL *)range_auto {return _range_auto;}

-(instancetype)init {
    self = [super init];
    _speech_on[0] = NO;
    _speech_on[1] = NO;
    _speech_on[2] = NO;
    _range_auto[0] = YES;
    _range_auto[1] = YES;
    return self;
}

-(instancetype) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    self = [self init];
    self.periph = periph;
    self.chars = [[NSMutableDictionary alloc]init];
    [self setDelegate:delegate];
    // Start an RSSI poller
    dispatch_async(dispatch_get_main_queue(),^(){[self RSSICB];});
    return self;
}

-(void)RSSICB {
    if(![self isConnected]) {
        return;
    }
    [self.periph readRSSIValueCompletion:^(NSNumber *RSSI, NSError *error) {
        if(RSSI) {
            [self.delegate onRssiReceived:[RSSI intValue]];
        }
        // Can only dispatch this timer from the main queue
        dispatch_async(dispatch_get_main_queue(),^{
            [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(RSSICB) userInfo:nil repeats:NO];
        });

    }];
}

-(NSString*)getPreferenceKeyString:(NSString*)tail {
    NSMutableString* rval = [NSMutableString stringWithString:@"mooshimeter-"];
    [rval appendString:self.periph.UUIDString];
    [rval appendString:@"-"];
    [rval appendString:tail];
    return rval;
}

-(BOOL)getPreference:(NSString*)shortkey {
    return [self getPreference:shortkey def:false];
}
-(BOOL)getPreference:(NSString*)shortkey def:(BOOL)def {
    return [Prefman getPreference:[self getPreferenceKeyString:shortkey] def:def];
}
-(void)setPreference:(NSString*)shortkey value:(BOOL)value{
    [Prefman setPreference:[self getPreferenceKeyString:shortkey] value:value];
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
+(BOOL)isPeripheralInOADMode:(LGPeripheral *)periph {
    CBUUID* oad_uuid = [BLEUtility expandToMooshimUUID:OAD_SERVICE_UUID];
    if(periph.cbPeripheral.state!=CBPeripheralStateConnected) {
        // If we're not connected to the device, judge by advertising data
        NSArray* adv_serv = [periph.advertisingData valueForKey:@"kCBAdvDataServiceUUIDs"];
        return adv_serv != nil
            && adv_serv.count>=1
            && [oad_uuid isEqual:adv_serv[0]];
    }
    // If we've made it here, the peripheral is connected.  Just look at the discovered services (advertising data might be out of date)
    for(LGService* service in periph.services) {
        if([service.UUIDString isEqualToString:[oad_uuid UUIDString]]) {
            return true;
        }
    }
    return NO;
}
+(Class)chooseSubClass:(LGPeripheral *)connected_peripheral {
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
        NSLog(@"Wrapping as a new style meter");
        rval = [MooshimeterDevice class];
    }
    return rval;
}

#pragma mark MooshimeterControlProtocol_methods

-(BOOL)isInOADMode {
    return [MooshimeterDeviceBase isPeripheralInOADMode:self.periph];
}
-(BOOL)isConnected {
    return self.periph.cbPeripheral.state == CBPeripheralStateConnected;
}
-(LGCharacteristic*)getLGChar:(uint16)UUID {
    return self.chars[[NSNumber numberWithInt:UUID]];
}
// Filler control methods to suppress warnings

- (int)initialize {return 0;}
- (void)reboot {}
- (BOOL)bumpRange:(Channel)c expand:(BOOL)expand {return NO;}
- (BOOL)applyAutorange {return NO;}
- (void)setName:(NSString *)name {}
- (NSString *)getName {return nil;}
- (void)pause {}
- (void)oneShot {}
- (void)stream {}
- (BOOL)isStreaming {return NO;}
- (void)enterShippingMode {}
- (int)getPCBVersion {return 0;}
- (double)getUTCTime {return 0;}
- (void)setTime:(double)utc_time {}
- (MeterReading *)getOffset:(Channel)c {return nil;}
- (void)setOffset:(Channel)c offset:(float)offset {}
- (int)getSampleRateHz {return 0;}
- (int)getSampleRateIndex {return 0;}
- (int)setSampleRateIndex:(int)i {return 0;}
- (NSArray<NSString *> *)getSampleRateList {return nil;}
- (int)getBufferDepth {return 0;}
- (int)setBufferDepthIndex:(int)i {return 0;}
- (NSArray<NSString *> *)getBufferDepthList {return nil;}
- (void)setBufferMode:(Channel)c on:(BOOL)on {}
- (BOOL)getLoggingOn {return NO;}
- (void)setLoggingOn:(BOOL)on {}
- (int)getLoggingStatus {return 0;}
- (NSString *)getLoggingStatusMessage {return nil;}
- (void)setLoggingInterval:(int)ms {}
- (int)getLoggingIntervalMS {return 0;}
- (MeterReading *)getValue:(Channel)c {return nil;}
- (NSString *)getRangeLabel:(Channel)c {return nil;}
- (int)setRange:(Channel)c rd:(RangeDescriptor *)rd {return 0;}
- (NSArray<RangeDescriptor *> *)getRangeList:(Channel)c {return nil;}
- (NSArray<NSString *> *)getRangeNameList:(Channel)c {return nil;}
- (NSString *)getInputLabel:(Channel)c {return nil;}
- (int)setInput:(Channel)c descriptor:(InputDescriptor *)descriptor {return 0;}
- (NSArray *)getInputList:(Channel)c {return nil;}
- (NSArray *)getInputNameList:(Channel)c {return nil;}
- (InputDescriptor *)getSelectedDescriptor:(Channel)c {return nil;}

-(void)removeDelegate {
    self.delegate = [[DummyDelegate alloc]init];
}

/*
 For convenience, builds a dictionary of the LGCharacteristics based on the relevant
 2 bytes of their UUID
 @param characteristics An array of LGCharacteristics
 @return void
 */

-(void)populateLGDict:(NSArray*)characteristics {
    for (LGCharacteristic* c in characteristics) {
        NSLog(@"    Char: %@", c.UUIDString);
        uint16 lookup;
        [c.cbCharacteristic.UUID.data getBytes:&lookup range:NSMakeRange(2, 2)];
        lookup = NSSwapShort(lookup);
        NSNumber* key = [NSNumber numberWithInt:lookup];
        self.chars[key] = c;
    }
}

@end