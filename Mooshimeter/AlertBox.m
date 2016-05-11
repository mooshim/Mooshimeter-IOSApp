//
// Created by James Whong on 4/28/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "AlertBox.h"

@implementation AlertBox

+(AlertBox*)displayOptions:(NSString*)title message:(NSString*)message options:(NSArray<NSString*>*)options callback:(void(^)(int))callback {
    // We maintain this strong reference here because we don't want to force the higher level
    // to maintain a strongref to it.  And the AlertView only weakly references the delegate, so if
    // we don't maintain a strongref to it somewhere the result of the AlertView never lands anywhere.
    static AlertBox * active_ref = nil;
    active_ref = [[AlertBox alloc] initWithTitle:title message:message options:options callback:callback];
    return active_ref;
}

-(instancetype)initWithTitle:(NSString*)title message:(NSString*)message options:(NSArray<NSString*>*)options callback:(void(^)(int))callback {
    self = [super init];
    self.select_cb = callback;
    self.av = [[UIAlertView alloc]
            initWithTitle:title
                  message:message
                 delegate:self
        cancelButtonTitle:nil
        otherButtonTitles:nil];
    for(NSString* option in options) {
        [self.av addButtonWithTitle:option];
    }
    [self.av show];
    return self;
}

#pragma mark UIAlertViewDelegate methods

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"clickedButtonAtIndex");
    if(self.select_cb==nil) {
        return;
    }
    self.select_cb(buttonIndex);
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"didDismissWithButtonIndex");
    if(self.select_cb==nil) {
        return;
    }
    self.select_cb(buttonIndex);
}
-(void)alertViewCancel:(UIAlertView *)alertView {
    NSLog(@"alertViewCancel");
}
@end