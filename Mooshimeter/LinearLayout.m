//
// Created by James Whong on 10/10/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "LinearLayout.h"
#import <objc/runtime.h>

@interface LLParams:NSObject
@property float width, height, weight;
@end
@implementation LLParams
-(instancetype)init {
    self.height=0;
    self.width=0;
    self.weight=0;
    return self;
}
@end

@implementation UIView (LinearLayoutExtension)
-(LLParams*)getLLParams {
    LLParams * rval = objc_getAssociatedObject(self,"_LL_extensions");
    if(rval==nil) {
        rval = [[LLParams alloc]init];
        objc_setAssociatedObject(self,"_LL_extensions",rval,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return rval;
}
-(float)getLLSize {
    return [self getLLParams].width;
}
-(float)getLLHeight {
    return [self getLLParams].height;
}
-(void)setLLSize:(float)width {
    [self getLLParams].width = width;
}
-(void)setLLHeight:(float)height {
    [self getLLParams].height = height;
}
-(float)getLLWeight {
    return [self getLLParams].weight;
}
-(void)setLLWeight:(float)weight {
    [self getLLParams].weight = weight;
}
@end

@implementation LinearLayout {

}
-(void)layoutSubviews {
    float w = self.frame.size.width;
    float h = self.frame.size.height;
    float off = 0;
    // Accumulate weights
    float total_weight = 0;
    float extra_space = self.direction==LAYOUT_HORIZONTAL?w:h;
    for(UIView* view in self.subviews) {
        total_weight += [view getLLWeight];
        extra_space  -= [view getLLSize];
    }
    if(total_weight==0) {
        total_weight = 1;
    }
    for(UIView* view in self.subviews) {
        float new_size = [view getLLSize]+extra_space*[view getLLWeight]/total_weight;
        if(self.direction==LAYOUT_HORIZONTAL) {
            view.frame = CGRectMake(off,0,
                    new_size,
                    h);
        } else {
            view.frame = CGRectMake(0,off,
                    w,
                    new_size);
        }
        off+=new_size;
    }
}
@end