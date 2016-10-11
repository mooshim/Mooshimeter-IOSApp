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
@end

@interface LinearLayout : UIView
@property enum layout_dir_t direction;
@end