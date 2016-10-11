//
// Created by James Whong on 10/10/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlockWrapper:NSObject
@property void(^callback)();
-(void)callTheCallback;
-(instancetype)initAndAttachTo:(UIControl*)control forEvent:(UIControlEvents)forEvent callback:(void(^)())callback;
@end