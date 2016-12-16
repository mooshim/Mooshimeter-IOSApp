//
// Created by James Whong on 12/13/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MinMaxTracker.h"


@implementation MinMaxTracker
#pragma mark initializer
-(instancetype)init {
    self = [super init];
    [self clear];
    return self;
}

#pragma mark public methods
-(void)clear {
    _min = CGFLOAT_MAX;
    _max =-CGFLOAT_MAX;
}
-(BOOL)process:(float)arg {
    if(arg < _min) {
        _min = arg;
        return YES;
    }
    if(arg > _max) {
        _max = arg;
        return YES;
    }
    return NO;
}
@end