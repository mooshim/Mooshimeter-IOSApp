//
// Created by James Whong on 10/10/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "BlockWrapper.h"
#import <objc/runtime.h>

@implementation BlockWrapper
-(instancetype)initWithCallback:(void(^)())callback{
    self = [super init];
    self.callback = callback;
    return self;
}
-(instancetype)initAndAttachTo:(UIControl*)control forEvent:(UIControlEvents)forEvent callback:(void(^)())callback{
    self = [super init];
    self.callback = callback;
    // Attach this object to the control so we keep existing as long as it does
    objc_setAssociatedObject( control, "_blockWrapper", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
    [control addTarget:self action:@selector(callTheCallback) forControlEvents:forEvent];
    return self;
}
-(void)callTheCallback {
    if(self.callback!=nil) {
        self.callback();
    }
}
@end