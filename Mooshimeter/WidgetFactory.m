//
// Created by James Whong on 5/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "WidgetFactory.h"
#import "SmartNavigationController.h"
#import <objc/runtime.h>

//////////////////////////
// Private helper classes
//////////////////////////

@interface BlockWrapper:NSObject
@property void(^callback)();
-(void)callTheCallback;
@end
@implementation BlockWrapper
-(instancetype)initWithCallback:(void(^)())callback{
    self.callback = callback;
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

@interface AlertViewBlockWrapper:NSObject<UIAlertViewDelegate>
@property void(^callback)(UIAlertView*,int);
@property (weak) UIAlertView * alertView;
@end
@implementation AlertViewBlockWrapper
-(instancetype)initAndAttachTo:(UIAlertView*)alertView callback:(void(^)(UIAlertView*,int))callback{
    self = [super init];
    self.callback = callback;
    // Attach this object to the control so we keep existing as long as it does
    objc_setAssociatedObject( alertView, "_blockWrapper", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
    [alertView setDelegate:self];
    self.alertView = alertView;
    return self;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.callback(self.alertView,buttonIndex);
}
@end

//////////////////
// Implementation of public interfaces
//////////////////

@implementation CG
+(CGRect)centerIn:(CGRect)in new_size:(CGSize)new_size {
    float cx = in.origin.x+(in.size.width/2.0f);
    float cy = in.origin.y+(in.size.height/2.0f);
    return CGRectMake(  cx-new_size.width/2.0f,
                        cy-new_size.height/2.0f,
                        new_size.width,
                        new_size.height);
}
+(CGRect)alignLeft:(CGRect)from to:(CGRect)to {
    CGRect rval = from;
    rval.origin.x = to.origin.x;
    return rval;
}
+(CGRect)alignRight:(CGRect)from to:(CGRect)to {
    CGRect rval = from;
    rval.origin.x = to.origin.x;
    rval.origin.x+= to.size.width;
    rval.origin.x-= from.size.width;
    return rval;
}
+(CGRect)alignTop:(CGRect)from to:(CGRect)to {
    CGRect rval = from;
    rval.origin.y = to.origin.y;
    return rval;
}
+(CGRect)alignBottom:(CGRect)from to:(CGRect)to {
    CGRect rval = from;
    rval.origin.y = to.origin.y;
    rval.origin.y+= to.size.height;
    rval.origin.y-= from.size.height;
    return rval;
}
@end

@implementation WidgetFactory
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback frame:(CGRect)frame {
    UIButton * rval = [WidgetFactory makeButton:title callback:callback];
    [rval setFrame:frame];
    return rval;
}
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback {
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b.layer.borderWidth = 2;
    b.layer.cornerRadius = 5;
    b.titleLabel.adjustsFontSizeToFitWidth = YES;

    [[BlockWrapper alloc]initAndAttachTo:b forEvent:UIControlEventTouchUpInside callback:callback];

    return b;
}
+(UISwitch*)makeSwitch:(void(^)(bool))callback frame:(CGRect)frame {
    UISwitch* rval = [WidgetFactory makeSwitch:callback];
    [rval setFrame:frame];
    return rval;
}
+(UISwitch*)makeSwitch:(void(^)(bool))callback {
    UISwitch * rval = [[UISwitch alloc]init];
    __weak UISwitch * weak = rval;
    [[BlockWrapper alloc] initAndAttachTo:rval forEvent:UIControlEventValueChanged callback:^{
        callback([weak isOn]);
    }];
    return rval;
}

+(UIAlertView*)makeCancelContinueAlert:(NSString*)title msg:(NSString*)msg callback:(void(^)(bool proceed))callback {
    UIAlertView* a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
    a.alertViewStyle = UIAlertViewStyleDefault;
    [[AlertViewBlockWrapper alloc] initAndAttachTo:a callback:^(UIAlertView *view, int i) {
        callback([view cancelButtonIndex]!=i);
    }];
    [a show];
    return a;
}

+(UIAlertView*)makeTextInputBox:(NSString*)title msg:(NSString*)msg callback:(void(^)(NSString*))callback {
    UIAlertView* a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[AlertViewBlockWrapper alloc] initAndAttachTo:a callback:^(UIAlertView *view, int i) {
        if(i== [view cancelButtonIndex]) {
            NSLog(@"Alert view canceled");
            return;
        }
        NSString* recv =[[view textFieldAtIndex:0] text];
        NSLog(@"Alert view received %@",recv);
        callback(recv);
    }];
    [a show];
    return a;
}

+(UIView*)makePopoverFromView:(Class)view_class size:(CGSize)size {
    UIViewController * top = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(top.presentedViewController!=nil) {
        top = top.presentedViewController;
    }
    // Instantiate the client
    CGRect client_frame = [CG centerIn:top.view.frame new_size:size];
    UIView* client_view = [[view_class alloc] initWithFrame:client_frame];
    client_view.alpha = 0.0;
    client_view.layer.cornerRadius = 5;
    client_view.layer.masksToBounds = YES;

    // Create a background button that will dismiss the client and itself
    UIButton* dismiss = [UIButton buttonWithType:UIButtonTypeSystem];
    dismiss.frame = top.view.frame;
    dismiss.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    __weak UIButton* weak_dismiss = dismiss;
    [[BlockWrapper alloc] initAndAttachTo:dismiss forEvent:UIControlEventTouchUpInside callback:^{
        [UIView animateWithDuration:0.2 animations:^{
            weak_dismiss.alpha = 0.0;
        } completion:^(BOOL finished) {
            [weak_dismiss removeFromSuperview];
        }];
    }];

    [top.view addSubview:dismiss];
    [top.view bringSubviewToFront:dismiss];
    [dismiss addSubview:client_view];
    [dismiss bringSubviewToFront:client_view];

    [UIView animateWithDuration:0.2 animations:^{
        dismiss.alpha = 1.0;
        client_view.alpha = 1.0;
    }];

    return client_view;
}
@end