//
// Created by James Whong on 5/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

// Makes widgets and applies standard styling

@interface WidgetFactory : NSObject
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback frame:(CGRect)frame;
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback;

+(UISwitch*)makeSwitch:(void(^)(bool))callback frame:(CGRect)frame;
+(UISwitch*)makeSwitch:(void(^)(bool))callback;

+(UIAlertView*)makeCancelContinueAlert:(NSString*)title msg:(NSString*)msg callback:(void(^)(bool proceed))callback;
+(UIAlertView*)makeTextInputBox:(NSString*)title msg:(NSString*)msg callback:(void(^)(NSString*))callback;
@end