//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MooshimeterControlProtocol.h"
#import "LGPeripheral.h"

@class LGCharacteristic;

@interface MooshimeterDeviceBase : NSObject<MooshimeterControlProtocol> {
    bool _range_auto[2];
    bool _speech_on[2];
}

@property id<MooshimeterDelegateProtocol> delegate;
@property bool rate_auto;
@property bool depth_auto;
@property (readonly) bool* range_auto;
@property (readonly) bool* speech_on;
@property LGPeripheral* periph;
@property NSMutableDictionary <NSNumber*,LGCharacteristic*>* chars;

+(MooshimeterDeviceBase *)chooseSubClass:(LGPeripheral *)connected_peripheral;

-(void)addDelegate:(id<MooshimeterDelegateProtocol>)d;
-(void)removeDelegate;

+(uint32)getBuildTimeFromPeripheral:(LGPeripheral *)periph;
@end