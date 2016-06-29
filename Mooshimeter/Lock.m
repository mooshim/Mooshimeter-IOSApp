//
// Created by James Whong on 6/29/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "Lock.h"


@implementation Lock {
    dispatch_semaphore_t l;
}
-(instancetype)init {
    self = [super init];
    l = dispatch_semaphore_create(0);
    return self;
}
-(int)wait:(int)ms {
    int rval = dispatch_semaphore_wait(l,dispatch_time(DISPATCH_TIME_NOW,ms*NSEC_PER_MSEC));
    if(rval) {
        NSLog(@"Timeout!");
        NSLog(@"%@",[NSThread callStackSymbols]);
    }
    return rval;
}
-(int)signal {
    dispatch_semaphore_signal(l);
}
@end