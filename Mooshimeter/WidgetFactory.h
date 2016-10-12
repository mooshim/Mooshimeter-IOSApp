//
// Created by James Whong on 5/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface CG:NSObject

+(CGRect)centerIn:(CGRect)in new_size:(CGSize)new_size;
+(CGRect)centerHorz:(CGRect)in new_size:(CGSize)new_size;
+(CGRect)centerVert:(CGRect)in new_size:(CGSize)new_size;
+(CGRect)alignLeft:(CGRect)from to:(CGRect)to;
+(CGRect)alignRight:(CGRect)from to:(CGRect)to;
+(CGRect)alignBottom:(CGRect)from to:(CGRect)to;
+(CGRect)alignTop:(CGRect)from to:(CGRect)to;

+(CGRect)abutLeft:(CGRect)from to:(CGRect)to;
+(CGRect)abutRight:(CGRect)from to:(CGRect)to;
+(CGRect)abutBottom:(CGRect)from to:(CGRect)to;
+(CGRect)abutTop:(CGRect)from to:(CGRect)to;
@end

// Makes widgets and applies standard styling

@interface WidgetFactory : NSObject
+(UIButton*)makeButtonReflexive:(NSString*)title callback:(void(^)(UIButton*))callback;
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback;
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback frame:(CGRect)frame;

+(UILabel*)setButtonSubtitle:(UIButton *)button subtitle:(NSString*)subtitle;

+(UISwitch*)makeSwitch:(void(^)(bool))callback frame:(CGRect)frame;
+(UISwitch*)makeSwitch:(void(^)(bool))callback;

+(UIAlertView*)makeAlert:(NSString *)title msg:(NSString *)msg;
+(UIAlertView*)makeYesNoAlert:(NSString *)title msg:(NSString *)msg callback:(void(^)(bool proceed))callback;
+(UIAlertView*)makeTextInputBox:(NSString*)title msg:(NSString*)msg callback:(void(^)(NSString*))callback;

+(UIView*)makePopoverFromView:(UIView*)client_view size:(CGSize)size;
+(UIView*)makePopoverFromViewClass:(Class)view_class size:(CGSize)size;

+(MFMailComposeViewController*)makeEmailComposeWindow;
@end