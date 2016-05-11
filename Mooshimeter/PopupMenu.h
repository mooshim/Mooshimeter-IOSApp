//
// Created by James Whong on 4/28/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PopupMenu : NSObject<UIActionSheetDelegate>
@property void(^select_cb)(int);
@property UIActionSheet * sheet;
+(PopupMenu*)displayOptionsWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options callback:(void(^)(int))callback;
+(PopupMenu*)displayOptionsWithParent:(UIView*)parent title:(NSString*)title options:(NSArray<NSString*>*)options cancel:(NSString*)cancel callback:(void(^)(int))callback;
@end