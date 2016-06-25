//
// Created by James Whong on 4/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MeterReading : NSObject
@property float value;
@property int n_digits;
@property float max;
@property NSString* format;
@property float format_mult;
@property int format_prefix;
@property NSString* units;

-(MeterReading*)initWithValue:(float)value_arg n_digits_arg:(int)n_digits_arg max_arg:(float)max_arg units_arg:(NSString*)units_arg;
-(NSString*)toString;
-(BOOL)isInRange;

+(MeterReading*) mult:(MeterReading*)m0 m1:(MeterReading*)m1;

@end