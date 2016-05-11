//
// Created by James Whong on 4/28/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AlertBox : NSObject<UIAlertViewDelegate>
@property void(^select_cb)(int);
@property UIAlertView * av;
+(AlertBox*)displayOptions:(NSString*)title message:(NSString*)message options:(NSArray<NSString*>*)options callback:(void(^)(int))callback;
@end