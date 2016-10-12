//
// Created by James Whong on 5/12/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "WidgetFactory.h"
#import "SmartNavigationController.h"
#import "BlockWrapper.h"
#import <objc/runtime.h>
#import <MessageUI/MessageUI.h>

//////////////////////////
// Private helper classes
//////////////////////////

@interface MailComposeDummyDelegate:NSObject<MFMailComposeViewControllerDelegate>
@property (weak) MFMailComposeViewController * vc;
@end
@implementation MailComposeDummyDelegate
-(instancetype)initAndAttachTo:(MFMailComposeViewController*)mailview {
    self = [super init];
    self.vc = mailview;
    // Attach this object to the control so we keep existing as long as it does
    objc_setAssociatedObject( mailview, "_dummydelegate", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
    [mailview setMailComposeDelegate:self];
    return self;
}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self.vc dismissViewControllerAnimated:YES completion:nil];
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

+(CGRect)centerVert:(CGRect)in new_size:(CGSize)new_size {
    float cy = in.origin.y + (in.size.height / 2.0f);
    in.origin.y = cy - new_size.height / 2.0f;
    in.size = new_size;
    return in;
}
+(CGRect)centerHorz:(CGRect)in new_size:(CGSize)new_size {
    float cx = in.origin.x + (in.size.width / 2.0f);
    in.origin.x = cx - new_size.width / 2.0f;
    in.size = new_size;
    return in;
}
+(CGRect)centerIn:(CGRect)in new_size:(CGSize)new_size {
    return [CG centerVert:[CG centerHorz:in new_size:new_size] new_size:new_size];
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
+(CGRect)abutLeft:(CGRect)from to:(CGRect)to {
    from.origin.x = to.origin.x+to.size.width;
    return from;
}
+(CGRect)abutRight:(CGRect)from to:(CGRect)to {
    from.origin.x = to.origin.x-from.size.width;
    return from;
}
+(CGRect)abutBottom:(CGRect)from to:(CGRect)to {
    from.origin.y = to.origin.y+to.size.height;
    return from;
}
+(CGRect)abutTop:(CGRect)from to:(CGRect)to {
    from.origin.y = to.origin.y-from.size.height;
    return from;
}

@end

@implementation WidgetFactory
+(UIButton*)makeMyStyleButton {
    UIButton* b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b.titleLabel setFont:[UIFont systemFontOfSize:24]];
    //[b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b.layer.borderWidth = 1;
    //b.layer.cornerRadius = 5;
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    return b;
}
+(UIButton*)makeButtonReflexive:(NSString*)title callback:(void(^)(UIButton*))callback{
    UIButton* b = [WidgetFactory makeMyStyleButton];
    [b setTitle:title forState:UIControlStateNormal];
    __weak UIButton* wb = b;
    void (^tmp_cb)() = ^void() {
        callback(wb);
    };
    (void)[[BlockWrapper alloc]initAndAttachTo:b forEvent:UIControlEventTouchUpInside callback:tmp_cb];
    return b;
}
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback frame:(CGRect)frame {
    UIButton *b=[WidgetFactory makeButton:title callback:callback];
    [b setFrame:frame];
    return b;
}
+(UIButton*)makeButton:(NSString*)title callback:(void(^)())callback {
    UIButton* b = [WidgetFactory makeMyStyleButton];
    [b setTitle:title forState:UIControlStateNormal];
    (void)[[BlockWrapper alloc]initAndAttachTo:b forEvent:UIControlEventTouchUpInside callback:callback];
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
    (void)[[BlockWrapper alloc] initAndAttachTo:rval forEvent:UIControlEventValueChanged callback:^{
        callback([weak isOn]);
    }];
    return rval;
}

+(UILabel*)setButtonSubtitle:(UIButton *)button subtitle:(NSString*)subtitle {
    const char* key = "_moosh_subtitle";
    UILabel* rval = objc_getAssociatedObject( button, key );
    if(rval == nil) {
        CGRect r = button.titleLabel.frame;
        // Shift the existing label up a bit
        [button setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
        float topinset = button.frame.size.height-40; // 40 = guessing at label height FIXME
        topinset /= 2;
        topinset -= 10;
        topinset = topinset<0?0:topinset;
        [button setTitleEdgeInsets:UIEdgeInsetsMake(topinset,0.0f,0.0f,0.0f)];
        rval = [[UILabel alloc]init];
        rval.frame = CGRectOffset(button.bounds,0,12);
        rval.frame = CGRectMake(0,rval.frame.origin.y,button.bounds.size.width,rval.frame.size.height);
        rval.font = [UIFont systemFontOfSize:12];
        rval.textColor = button.titleLabel.textColor;
        rval.textAlignment = NSTextAlignmentCenter;
        [button addSubview:rval];
        objc_setAssociatedObject(button,key,rval,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    rval.text = subtitle;
    return rval;
}

+(UIAlertView*)makeAlert:(NSString *)title msg:(NSString *)msg {
    UIAlertView* a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    a.alertViewStyle = UIAlertViewStyleDefault;
    [a show];
    return a;
}

+(UIAlertView*)makeYesNoAlert:(NSString *)title msg:(NSString *)msg callback:(void(^)(bool proceed))callback {
    UIAlertView* a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    a.alertViewStyle = UIAlertViewStyleDefault;
    (void)[[AlertViewBlockWrapper alloc] initAndAttachTo:a callback:^(UIAlertView *view, int i) {
        callback([view cancelButtonIndex]!=i);
    }];
    [a show];
    return a;
}

+(UIAlertView*)makeTextInputBox:(NSString*)title msg:(NSString*)msg callback:(void(^)(NSString*))callback {
    UIAlertView* a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    (void)[[AlertViewBlockWrapper alloc] initAndAttachTo:a callback:^(UIAlertView *view, int i) {
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

+(UIView*)makePopoverFromView:(UIView*)client_view size:(CGSize)size {
    UIViewController * top = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(top.presentedViewController!=nil) {
        top = top.presentedViewController;
    }
    // Instantiate the client
    CGRect client_frame = [CG centerIn:top.view.frame new_size:size];
    [client_view setFrame:client_frame];
    client_view.alpha = 0.0;
    client_view.layer.cornerRadius = 5;
    client_view.layer.masksToBounds = YES;

    // Create a background button that will dismiss the client and itself
    UIButton* dismiss = [UIButton buttonWithType:UIButtonTypeSystem];
    dismiss.frame = top.view.frame;
    dismiss.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    __weak UIButton* weak_dismiss = dismiss;
    (void)[[BlockWrapper alloc] initAndAttachTo:dismiss forEvent:UIControlEventTouchUpInside callback:^{
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

+(UIView*)makePopoverFromViewClass:(Class)view_class size:(CGSize)size {
    UIViewController * top = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(top.presentedViewController!=nil) {
        top = top.presentedViewController;
    }
    // Instantiate the client
    CGRect client_frame = [CG centerIn:top.view.frame new_size:size];
    UIView* client_view = [[view_class alloc] initWithFrame:client_frame];
    [WidgetFactory makePopoverFromView:client_view size:size];
    return client_view;
}
+(MFMailComposeViewController*)makeEmailComposeWindow {
    if(![MFMailComposeViewController canSendMail]) {
        return nil;
    }
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    MailComposeDummyDelegate *md = [[MailComposeDummyDelegate alloc] initAndAttachTo:mc];
    return mc;
}
@end