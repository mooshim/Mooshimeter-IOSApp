//
// Created by James Whong on 4/28/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "PopupMenu.h"

@implementation PopupMenu

+(PopupMenu*)displayOptionsWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options callback:(void(^)(int))callback {
    return [[PopupMenu alloc] initWithParent:parent title:title options:options callback:callback];
}

-(instancetype)initWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options callback:(void(^)(int))callback {
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
    [self.sheet showInView:parent];
}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"Action sheet selected %d", buttonIndex);
}

-(void)actionSheetCancel:(UIActionSheet *)actionSheet {
    NSLog(@"Action sheet canceled");
}

@end