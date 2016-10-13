//
// Created by James Whong on 10/10/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum layout_dir_t {LAYOUT_HORIZONTAL,LAYOUT_VERTICAL};

@interface UIView (LinearLayoutExtension)
-(float)getLLSize;
-(void)setLLSize:(float)size;
-(float)getLLWeight;
-(void)setLLWeight:(float)weight;
-(float)getLLInset;
-(void)setLLInset:(float)inset;
@end

@protocol LinearLayoutProtocol
-(void)setDirection:(enum layout_dir_t)direction;
-(id<LinearLayoutProtocol>)initWithDirection:(enum layout_dir_t)direction;
@end

@interface LinearLayout : UIView <LinearLayoutProtocol>
@end

@interface ScrollingLinearLayout : UIScrollView <LinearLayoutProtocol>
@end