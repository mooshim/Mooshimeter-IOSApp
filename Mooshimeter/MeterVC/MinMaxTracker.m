//
// Created by James Whong on 12/13/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "MinMaxTracker.h"


@implementation MinMaxTracker {
    float sum;
}

#pragma mark getters/setters
-(float)getAvg {
    if(_n_samples==0) {
        return 0;
    }
    return sum/_n_samples;
}
#pragma mark initializer
-(instancetype)init {
    self = [super init];
    [self clear];
    return self;
}

#pragma mark public methods
-(void)clear {
    _min = CGFLOAT_MAX;
    _max = CGFLOAT_MIN;
    sum = 0;
    _n_samples = 0;
}
-(void)process:(float)arg {
    if(arg < _min) {
        _min = arg;
    }
    if(arg > _max) {
        _max = arg;
    }
    sum += arg;
    _n_samples++;
}
@end