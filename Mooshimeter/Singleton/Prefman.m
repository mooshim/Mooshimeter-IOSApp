//
// Created by James Whong on 6/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "Prefman.h"


@implementation Prefman {

}

+(bool)getPreference:(NSString*)key def:(bool)def {
    if([[NSUserDefaults standardUserDefaults] objectForKey:key]==nil) {
        // Key not found, return default
        return def;
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

+(void)setPreference:(NSString*)key value:(bool)value{
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
}

+(int)getPreferenceInt:(NSString*)key def:(int)def {
    if([[NSUserDefaults standardUserDefaults] objectForKey:key]==nil) {
        // Key not found, return default
        return def;
    }
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}
+(void)setPreferenceInt:(NSString*)key value:(int)value{
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
}

@end