//
// Created by James Whong on 6/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TempUnitsHelper : NSObject
+(float)absK2C:(float)K;
+(float)absK2F:(float)K;
+(float)absC2F:(float)C;
+(float)relK2F:(float)C;
+(float)KThermoVoltsToDegC:(float)v;
@end