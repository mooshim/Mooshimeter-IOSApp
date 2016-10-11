//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#include "MooshimeterProfileTypes.h"

#import <Foundation/Foundation.h>
#import "MooshimeterControlProtocol.h"
#import "MeterReading.h"
#import "RangeDescriptor.h"
#import "InputDescriptor.h"
#import "LogFile.h"

@protocol MooshimeterDelegateProtocol <NSObject>
@optional
-(void) onInit;
-(void) onDisconnect;
-(void) onRssiReceived:(int)rssi;
-(void) onBatteryVoltageReceived:(float)voltage;
-(void) onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading*)val;
-(void) onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber*>*)val;
-(void) onSampleRateChanged:(int)sample_rate_hz;
-(void) onBufferDepthChanged:(int)buffer_depth;
-(void) onLoggingStatusChanged:(BOOL)on new_state:(int)new_state message:(NSString*)message;
-(void) onRangeChange:(Channel)c new_range:(RangeDescriptor*)new_range;
-(void) onInputChange:(Channel)c descriptor:(InputDescriptor*)descriptor;
-(void) onOffsetChange:(Channel)c offset:(MeterReading*)offset;
-(void) onLogInfoReceived:(LogFile*)log;
-(void) onLogFileReceived:(LogFile*)log;
-(void) onLogDataReceived:(LogFile*)log data:(NSData*)data;
@end