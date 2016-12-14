//
// Created by James Whong on 6/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PREF_USE_FAHRENHEIT @"USE_FAHRENHEIT"
#define PREF_GRAPH_POINTS_ONSCREEN @"GRAPH_POINTS_ONSCREEN"
#define PREF_GRAPH_XY_MODE @"GRAPH_XY_MODE"
#define PREF_GRAPH_BUFFER_MODE @"GRAPH_BUFFER_MODE"
#define PREF_GRAPH_AUTOSCROLL @"GRAPH_AUTOSCROLL"
#define PREF_GRAPH_LEFT_AXIS_AUTO @"GRAPH_LEFT_AUTO"
#define PREF_GRAPH_RIGHT_AXIS_AUTO @"GRAPH_RIGHT_AUTO"

@interface Prefman : NSObject

+(bool)getPreference:(NSString*)key def:(bool)def;
+(void)setPreference:(NSString*)key value:(bool)value;

+(int)getPreferenceInt:(NSString*)key def:(int)def;
+(void)setPreferenceInt:(NSString*)key value:(int)value;
@end