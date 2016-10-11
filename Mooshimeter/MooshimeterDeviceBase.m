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
#import "GCD.h"


@implementation DistributorDelegate
-(instancetype)init {
    self = [super init];
    _children = [[NSMutableSet alloc]init];
    return self;
}
-(void) onInit {
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onInit)]) {
            [d onInit];
        }
    }
}
-(void) onDisconnect{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onDisconnect)]) {
            [d onDisconnect];
        }
    }
}
-(void) onRssiReceived:(int)rssi{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onRssiReceived:)]) {
            [d onRssiReceived:rssi];
        }
    }
}
-(void) onBatteryVoltageReceived:(float)voltage{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onBatteryVoltageReceived:)]) {
            [d onBatteryVoltageReceived:voltage];
        }
    }
}
-(void) onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading*)val{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onSampleReceived:c:val:)]) {
            [d onSampleReceived:timestamp_utc c:c val:val];
        }
    }
}
-(void) onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber*>*)val{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onBufferReceived:c:dt:val:)]) {
            [d onBufferReceived:timestamp_utc c:c dt:dt val:val];
        }
    }
}
-(void) onSampleRateChanged:(int)sample_rate_hz{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if ([d respondsToSelector:@selector(onSampleRateChanged:)]) {
            [d onSampleRateChanged:sample_rate_hz];
        }
    }
}
-(void) onBufferDepthChanged:(int)buffer_depth{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onBufferDepthChanged:)]) {
            [d onBufferDepthChanged:buffer_depth];
        }
    }
}
-(void) onLoggingStatusChanged:(BOOL)on new_state:(int)new_state message:(NSString*)message{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onLoggingStatusChanged:new_state:message:)]) {
            [d onLoggingStatusChanged:on new_state:new_state message:message];
        }
    }
}
-(void) onRangeChange:(Channel)c new_range:(RangeDescriptor*)new_range{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onRangeChange:new_range:)]) {
            [d onRangeChange:c new_range:new_range];
        }
    }
}
-(void) onInputChange:(Channel)c descriptor:(InputDescriptor*)descriptor{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onInputChange:descriptor:)]) {
            [d onInputChange:c descriptor:descriptor];
        }
    }
}
-(void) onOffsetChange:(Channel)c offset:(MeterReading*)offset{
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onOffsetChange:offset:)]) {
            [d onOffsetChange:c offset:offset];
        }
    }
}
-(void) onLogInfoReceived:(LogFile*)log {
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onLogInfoReceived:)]) {
            [d onLogInfoReceived:log];
        }
    }
}
-(void) onLogFileReceived:(LogFile*)log {
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onLogFileReceived:)]) {
            [d onLogFileReceived:log];
        }
    }
}
-(void) onLogDataReceived:(LogFile*)log data:(NSData*)data {
    for(id<MooshimeterDelegateProtocol> d in _children) {
        if([d respondsToSelector:@selector(onLogDataReceived:data:)]) {
            [d onLogDataReceived:log data:data];
        }
    }
}
@end

@interface MooshimeterDeviceBase()
@property DistributorDelegate* delegate;
@end
@implementation MooshimeterDeviceBase {
    BOOL rssi_poller_running;
}

- (BOOL *)speech_on {return _speech_on;}

-(instancetype)init {
    self = [super init];
    rssi_poller_running = NO;
    _speech_on[0] = NO;
    _speech_on[1] = NO;
    _speech_on[2] = NO;
    _delegate = [[DistributorDelegate alloc]init];
    return self;
}

-(instancetype) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    self = [self init];
    self.periph = periph;
    self.chars = [[NSMutableDictionary alloc]init];
    [self addDelegate:delegate];
    if(periph!=nil) {
        [self startRSSIPoller];
    }
    return self;
}

-(void)startRSSIPoller {
    if(rssi_poller_running) {
        return;
    }
    rssi_poller_running = YES;
    [GCD asyncBack:^{[self RSSICB];}];
}

-(void)RSSICB {
    if(![self isConnected]) {
        return;
    }
    [self.periph readRSSIValueCompletion:^(NSNumber *RSSI, NSError *error) {
        if(RSSI) {
            [GCD asyncBack:^{
                [self.delegate onRssiReceived:[RSSI intValue]];
            }];
        }
    }];
    [GCD asyncMainAfterMS:5000 block:^{[self RSSICB];}];
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

-(uint32)getBuildTime {
    return [MooshimeterDeviceBase getBuildTimeFromPeripheral:self.periph];
}

#pragma mark getter/setter

-(BOOL)rate_auto {
    return [self getPreference:@"RATE_AUTO" def:YES];
}
-(void)setRate_auto:(BOOL)rate_auto {
    [self setPreference:@"RATE_AUTO" value:rate_auto];
    [self.delegate onSampleRateChanged:[self getSampleRateHz]];
}
-(BOOL)depth_auto {
    return [self getPreference:@"DEPTH_AUTO" def:YES];
}
-(void)setDepth_auto:(BOOL)Depth_auto {
    [self setPreference:@"DEPTH_AUTO" value:Depth_auto];
    [self.delegate onBufferDepthChanged:[self getBufferDepth]];
}
-(BOOL)ch1_range_auto {
    return [self getPreference:@"CH1_RANGE_AUTO"];
}
-(void)setCh1_range_auto:(BOOL)ch1_range_auto {
    [self setPreference:@"CH1_RANGE_AUTO" value:ch1_range_auto];
    [self.delegate onRangeChange:CH1 new_range:[self getSelectedRange:CH1]];
}
-(BOOL)ch2_range_auto {
    return [self getPreference:@"CH2_RANGE_AUTO"];
}
-(void)setCh2_range_auto:(BOOL)ch2_range_auto {
    [self setPreference:@"CH2_RANGE_AUTO" value:ch2_range_auto];
    [self.delegate onRangeChange:CH2 new_range:[self getSelectedRange:CH2]];
}

-(void)setAutorangeOn:(Channel)c val:(BOOL)val {
    switch(c) {
        case CH1:
            self.ch1_range_auto = val;
            break;
        case CH2:
            self.ch2_range_auto = val;
            break;
        default:
            break;
    }
}
-(BOOL)getAutorangeOn:(Channel)c {
    switch(c) {
        case CH1:
            return self.ch1_range_auto;
        case CH2:
            return self.ch2_range_auto;
        default:
            return NO;
    }
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
- (NSString *)getName {return self.periph.name;}
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
- (RangeDescriptor*)getSelectedRange:(Channel)c {
    return nil;
}

-(void)addDelegate:(id<MooshimeterDelegateProtocol>)delegate {
    if(delegate==nil){return;}
    [self.delegate.children addObject:delegate];
}
-(void)removeDelegate:(id<MooshimeterDelegateProtocol>)delegate {
    if(delegate==nil){return;}
    [self.delegate.children removeObject:delegate];
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