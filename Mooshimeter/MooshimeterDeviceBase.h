//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MooshimeterControlProtocol.h"
#import "LGPeripheral.h"

@class LGCharacteristic;

@interface MooshimeterDeviceBase : NSObject<MooshimeterControlProtocol>

@property id<MooshimeterDelegateProtocol> delegate;
@property bool rate_auto;
@property bool depth_auto;
@property NSArray * speech_on;
@property LGPeripheral* periph;
@property NSMutableDictionary <NSNumber*,LGCharacteristic*>* chars;

-(void)addDelegate:(id<MooshimeterDelegateProtocol>)d;
-(void)removeDelegate;
@end