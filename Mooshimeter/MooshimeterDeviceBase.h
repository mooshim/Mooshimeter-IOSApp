//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MooshimeterControlProtocol.h"
#import "LGPeripheral.h"

@class LGCharacteristic;

@interface DistributorDelegate:NSObject <MooshimeterDelegateProtocol>
@property NSMutableSet<id<MooshimeterDelegateProtocol>>* children;
@end

@interface MooshimeterDeviceBase : NSObject<MooshimeterControlProtocol> {
    BOOL _speech_on[3];
}

@property (readonly) DistributorDelegate* delegate;
@property BOOL rate_auto;
@property BOOL depth_auto;
@property BOOL ch1_range_auto;
@property BOOL ch2_range_auto;
@property (readonly) BOOL* speech_on;
@property LGPeripheral* periph;
@property NSMutableDictionary <NSNumber*,LGCharacteristic*>* chars;

+(Class)chooseSubClass:(LGPeripheral *)connected_peripheral;
-(void)populateLGDict:(NSArray*)characteristics;

-(instancetype) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate;
-(BOOL)isConnected;
-(uint32)getBuildTime;

-(void)setAutorangeOn:(Channel)c val:(BOOL)val;
-(BOOL)getAutorangeOn:(Channel)c;

+(uint32)getBuildTimeFromPeripheral:(LGPeripheral *)periph;
@end