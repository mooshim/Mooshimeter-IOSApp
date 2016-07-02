//
// Created by James Whong on 6/29/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "Lock.h"

@implementation Lock {
    NSCondition * l;
}
-(instancetype)init {
    self = [super init];
    l = [[NSCondition alloc] init];
    return self;
}
-(int)wait:(int)ms {
    int rval;
    [l lock];
    if(![l waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:(float)ms/1000.]]) {
        NSLog(@"Timeout!");
        NSLog(@"%@",[NSThread callStackSymbols]);
        rval = 1;
    } else {
        rval = 0;
    }
    [l unlock];
    return rval;
}
-(int)signal {
    [l lock];
    [l signal];
    [l unlock];
    return 0;
}
@end