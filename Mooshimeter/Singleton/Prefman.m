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
@end