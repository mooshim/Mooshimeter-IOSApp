//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputDescriptor.h"
#import "MeterReading.h"

@interface MathInputDescriptor : InputDescriptor
@property BOOL (^meterSettingsAreValid)();
@property void (^onChosen)();
@property MeterReading* (^calculate)();
@end