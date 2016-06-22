//
// Created by James Whong on 6/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: Maybe these should be properties?
#define PREF_USE_FAHRENHEIT @"USE_FAHRENHEIT"

@interface Prefman : NSObject

+(bool)getPreference:(NSString*)key def:(bool)def;
+(void)setPreference:(NSString*)key value:(bool)value;
@end