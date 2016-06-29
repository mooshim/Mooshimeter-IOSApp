//
// Created by James Whong on 6/29/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Lock : NSObject
-(int)wait:(int)ms;
-(int)signal;
@end