//
// Created by James Whong on 5/19/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeterReading.h"

@interface SpeaksOnLargeChange : NSObject
@property float last_value;
@property NSTimer* cooldown_timer;
@property BOOL cooldown_active;
-(BOOL)decideAndSpeak:(MeterReading*)val;
@end