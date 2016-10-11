//
// Created by James Whong on 6/29/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "GCD.h"


@implementation GCD {

}
+ (void)asyncMain:(void (^)())block {
    dispatch_async(dispatch_get_main_queue(),block);
}
+ (void)asyncBack:(void (^)())block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),block);
}
+ (void)syncMain:(void (^)())block {
    if([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(),block);
    }
}
+ (void)asyncMainAfterMS:(int)ms block:(void (^)())block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_MSEC*ms),dispatch_get_main_queue(),block);
}
+ (void)asyncBackAfterMS:(int)ms block:(void (^)())block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_MSEC*ms),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),block);
}
@end