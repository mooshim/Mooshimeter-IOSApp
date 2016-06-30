//
// Created by James Whong on 6/29/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DECLARE_WEAKSELF __weak typeof(self) ws = self;

@interface GCD : NSObject
+(void)asyncMain:(void(^)())block;
+(void)asyncBack:(void(^)())block;
+(void)syncMain:(void(^)())block;
+(void)asyncMainAfterMS:(int)ms block:(void(^)())block;
+(void)asyncBackAfterMS:(int)ms block:(void(^)())block;
@end