//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//
#include "MooshimeterProfileTypes.h"

#import <Foundation/Foundation.h>
#import "MooshimeterDelegateProtocol.h"
#import "MeterReading.h"
#import "LGCharacteristic.h"
#import "LogFile.h"

@protocol MooshimeterControlProtocol <NSObject>

@required
        -(int)initialize;
        -(void)addDelegate:(   id<MooshimeterDelegateProtocol>)delegate;
        -(void)removeDelegate:(id<MooshimeterDelegateProtocol>)delegate;
        -(void)reboot;

        ////////////////////////////////
        // Convenience functions
        ////////////////////////////////

        -(BOOL)isInOADMode;
        -(LGCharacteristic*)getLGChar:(uint16_t)UUID;

        //////////////////////////////////////
        // Autoranging
        //////////////////////////////////////

        -(BOOL)bumpRange:(Channel)c expand:(BOOL)expand;

        // Return true if settings changed
        -(BOOL)applyAutorange;

        //////////////////////////////////////
        // Interacting with the Mooshimeter itself
        //////////////////////////////////////

        -(void)setName:(NSString*)name;
        -(NSString*)getName;

        -(void)pause;
        -(void)oneShot;
        -(void)stream;
        -(BOOL)isStreaming;

        -(void)enterShippingMode;

        -(int)getPCBVersion;

        -(double)getUTCTime;
        -(void)setTime:(double) utc_time;

        -(MeterReading*) getOffset:(Channel)c;
        -(void)setOffset:(Channel)c offset:(float)offset;

        -(int)getSampleRateHz;
        -(int) getSampleRateIndex;
        -(int)setSampleRateIndex:(int)i;
        -(NSArray<NSString*>*) getSampleRateList;

        -(int)getBufferDepth;
        -(int)setBufferDepthIndex:(int)i;
        -(NSArray<NSString*>*) getBufferDepthList;

        -(void)setBufferMode:(Channel)c on:(BOOL)on;

        -(BOOL)getLoggingOn;
        -(void)setLoggingOn:(BOOL)on;
        -(int)getLoggingStatus;
        -(NSString*)getLoggingStatusMessage;
        -(void)setLoggingInterval:(int)ms;
        -(int)getLoggingIntervalMS;

        -(MeterReading*) getValue:(Channel)c;

        -(NSString*)   getRangeLabel:(Channel)c;
        -(int)         setRange:(Channel)c rd:(RangeDescriptor*)rd;
        -(NSArray<RangeDescriptor*>*)getRangeList:(Channel)c;
        -(NSArray<NSString*>*)getRangeNameList:(Channel)c;

        -(NSString*) getInputLabel:(Channel)c;
        -(int)setInput:(Channel)c descriptor:(InputDescriptor*)descriptor;
        -(NSArray<InputDescriptor*>*)getInputList:(Channel)c;
        -(NSArray<NSString*>*)getInputNameList:(Channel)c;
        -(InputDescriptor*) getSelectedDescriptor:(Channel)c;
        -(RangeDescriptor*) getSelectedRange:(Channel)c;

        // Preference management helpers
        -(NSString*)getPreferenceKeyString:(NSString*)tail;
        -(BOOL)getPreference:(NSString*)shortkey def:(BOOL)def;
        -(BOOL)getPreference:(NSString*)shortkey;
        -(void)setPreference:(NSString*)shortkey value:(BOOL)value;

        -(void)pollLogInfo;
        -(void)downloadLog:(LogFile*)log;
        -(void)cancelLogDownload;
        -(LogFile*) getLogInfo:(int)index;
        -(void) setLogOffset:(uint32_t)offset;
@end