//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//
#include "MooshimeterProfileTypes.h"

#import <Foundation/Foundation.h>
#import "MooshimeterDelegateProtocol.h"
#import "MeterReading.h"

@protocol MooshimeterControlProtocol <NSObject>

@required
        -(void)addDelegate:(id<MooshimeterDelegateProtocol>)d;
        -(void)removeDelegate;

        -(int)initialize;

        ////////////////////////////////
        // Convenience functions
        ////////////////////////////////

        -(bool)isInOADMode;

        //////////////////////////////////////
        // Autoranging
        //////////////////////////////////////

        -(bool)bumpRange:(Channel)c expand:(bool)expand;

        // Return true if settings changed
        -(bool)applyAutorange;

        //////////////////////////////////////
        // Interacting with the Mooshimeter itself
        //////////////////////////////////////

        -(void)setName:(NSString*)name;
        -(NSString*)getName;

        -(void)pause;
        -(void)oneShot;
        -(void)stream;

        -(void)enterShippingMode;

        -(int)getPCBVersion;

        -(double)getUTCTime;
        -(void)setTime:(double) utc_time;

        -(MeterReading*) getOffset:(Channel)c;
        -(void)setOffset:(Channel)c offset:(float)offset;

        -(int)getSampleRateHz;
        -(int)setSampleRateIndex:(int)i;
        -(NSArray<NSString*>*) getSampleRateList;

        -(int)getBufferDepth;
        -(int)setBufferDepthIndex:(int)i;
        -(NSArray<NSString*>*) getBufferDepthList;

        -(void)setBufferMode:(Channel)c on:(bool)on;

        -(bool)getLoggingOn;
        -(void)setLoggingOn:(bool)on;
        -(int)getLoggingStatus;
        -(NSString*)getLoggingStatusMessage;
        -(void)setLoggingInterval:(int)ms;
        -(int)getLoggingIntervalMS;

        -(MeterReading*) getValue:(Channel)c;

        NSString*       getRangeLabel(Channel c);
        -(int)         setRange:(Channel)c rd:(RangeDescriptor*)rd;
        -(NSArray<NSString*>*) getRangeList:(Channel)c;

        -(NSString*) getInputLabel:(Channel)c;
        -(int)setInput:(Channel)c descriptor:(InputDescriptor*)descriptor;
        -(NSArray *) getInputList:(Channel)c;
        -(InputDescriptor*) getSelectedDescriptor:(Channel)c;
@end