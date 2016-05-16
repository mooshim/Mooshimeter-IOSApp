//
// Created by James Whong on 5/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CG

+(CGRect)centerIn:(CGRect)in new_size:(CGSize)new_size;
+(CGRect)alignLeft:(CGRect)from to:(CGRect)to;
+(CGRect)alignRight:(CGRect)from to:(CGRect)to;
+(CGRect)alignBottom:(CGRect)from to:(CGRect)to;
+(CGRect)alignTop:(CGRect)from to:(CGRect)to;
@end

// Makes widgets and applies standard styling

@interface WidgetFactory : NSObject
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback frame:(CGRect)frame;
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback;

+(UISwitch*)makeSwitch:(void(^)(bool))callback frame:(CGRect)frame;
+(UISwitch*)makeSwitch:(void(^)(bool))callback;

+(UIAlertView*)makeCancelContinueAlert:(NSString*)title msg:(NSString*)msg callback:(void(^)(bool proceed))callback;
+(UIAlertView*)makeTextInputBox:(NSString*)title msg:(NSString*)msg callback:(void(^)(NSString*))callback;

+(UIView*)makePopoverFromView:(Class)view_class size:(CGSize)size;
@end