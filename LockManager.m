//
//  LockManager.m
//  Mooshimeter
//
//  Created by James Whong on 11/10/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import "LockManager.h"

@implementation LockManager

-(instancetype) init {
    // Check for issues with struct packing.
    self = [super init];
    self.locks = [[NSMutableDictionary alloc] init];
    return self;
}

-(void) createLock:(NSString*)name {
    NSLog(@"Creating lock %@", name);
    NSCondition* l = [[NSCondition alloc] init];
    [l lock];
    NSNumber* flag = [NSNumber numberWithBool:NO];
    NSMutableArray* val = [NSMutableArray arrayWithObjects:l, flag, nil];
    [self.locks setObject:val forKey:name];
}

-(BOOL) waitOnLock:(NSString*)name timeout:(NSTimeInterval)timeout {
    NSMutableArray *val = [self.locks objectForKey:name];
    if( val == nil ) {
        return 0;
    }
    NSCondition* lock = val[0];
    NSDate* abs_timeout = [NSDate dateWithTimeIntervalSinceNow:timeout];
    NSLog(@"Waiting on %@", name);
    while(1) {
        [lock waitUntilDate:abs_timeout];
        if( [abs_timeout compare:[NSDate date]] == NSOrderedAscending ) {
            NSLog(@"Timed out on %@", name);
            break;
        } else if( [val[1] boolValue] ) {
            NSLog(@"Successful awakening on %@", name);
            break;
        } else {
            NSLog(@"Spurious wakeup on %@", name);
        }
    }
    return [val[1] boolValue];
}

-(void) signalLock:(NSString*)name {
    NSMutableArray *val = [self.locks objectForKey:name];
    NSLog(@"Signaling %@", name);
    if( val == nil ) {
        NSLog(@"Tried to signal %@, but could not find the lock!", name);
        return;
    }
    NSCondition* l = val[0];
    [l lock];
    [l signal];
    [val setObject:[NSNumber numberWithBool:YES] atIndexedSubscript:1];
    [l unlock];
}

-(void) releaseLock:(NSString*)name {
    NSLog(@"Releasing lock %@", name);
    NSMutableArray *val = [self.locks objectForKey:name];
    if( val == nil ) {
        return;
    }
    NSCondition* l = val[0];
    [l unlock];
    [self.locks removeObjectForKey:name];
}

@end
