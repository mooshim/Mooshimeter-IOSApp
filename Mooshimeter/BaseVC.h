//
// Created by James Whong on 5/11/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BaseVC : UIViewController

@property float visible_w,visible_h;
@property int nrow,ncol;
@property UIView *content_view; // Portion of the view below the nav controller
@property BOOL busymsg_up;

-(void)populateNavBar;

-(CGRect)makeRectInGrid:(int)col_off row_off:(int)row_off
                  width:(int)col_w height:(int)row_h;

-(UIButton*)makeButton:(CGRect)frame cb:(SEL)cb;
-(void)addToNavBar:(UIView*)new_item;

-(void)setBusy:(BOOL)busy;
@end