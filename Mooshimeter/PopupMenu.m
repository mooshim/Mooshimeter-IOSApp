//
// Created by James Whong on 4/28/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "PopupMenu.h"

@implementation PopupMenu

+(PopupMenu*)displayOptionsWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options callback:(void(^)(int))callback {
    PopupMenu * rval = [PopupMenu displayOptionsWithParent:parent
                                                     title:title
                                                   options:options
                                                    cancel:nil
                                                  callback:callback];
    return rval;
}

+(PopupMenu*)displayOptionsWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options cancel:(NSString*)cancel callback:(void(^)(int))callback {
    // We maintain this strong reference here because we don't want to force the higher level
    // to maintain a strongref to it.  And the ActionSheet only weakly references the delegate, so if
    // we don't maintain a strongref to it somewhere the result of the actionsheet never lands anywhere.
    static PopupMenu * active_ref = nil;
    active_ref = [[PopupMenu alloc]
            initWithParent:parent
                     title:title
                   options:options
                    cancel:cancel
                  callback:callback];
    return active_ref;
}

-(instancetype)initWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options cancel:(NSString*)cancel callback:(void(^)(int))callback {
    self = [super init];
    self.select_cb = callback;
    self.sheet = [[UIActionSheet alloc]
            initWithTitle:title
                 delegate:self
        cancelButtonTitle:nil
   destructiveButtonTitle:nil
        otherButtonTitles:nil];
    for(NSString* option in options) {
        [self.sheet addButtonWithTitle:option];
    }
    if(cancel!=nil) {
        [self.sheet addButtonWithTitle:cancel];
    }
    [self.sheet addButtonWithTitle:@"Cancel"];
    [self.sheet setCancelButtonIndex:[self.sheet numberOfButtons]-1];
    [self.sheet showInView:parent];
    return self;
}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"Action sheet selected %d", buttonIndex);
    if( buttonIndex==self.sheet.cancelButtonIndex) {
        return;
    }
    self.select_cb(buttonIndex);
}

-(void)actionSheetCancel:(UIActionSheet *)actionSheet {
    NSLog(@"Action sheet canceled");
}

@end