//
// Created by James Whong on 10/10/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "LinearLayout.h"
#import <objc/runtime.h>

@interface LLParams:NSObject
@property float size,weight,inset;
@end
@implementation LLParams
-(instancetype)init {
    self.size=0;
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
    return [self getLLParams].size;
}
-(void)setLLSize:(float)size {
    [self getLLParams].size = size;
}
-(float)getLLWeight {
    return [self getLLParams].weight;
}
-(void)setLLWeight:(float)weight {
    [self getLLParams].weight = weight;
}
-(float)getLLInset {
    return [self getLLParams].inset;
}
-(void)setLLInset:(float)inset {
    [self getLLParams].inset = inset;
}
@end

@interface LinearLayout()
@property enum layout_dir_t direction;
@end

@implementation LinearLayout {

}
-(instancetype)initWithDirection:(enum layout_dir_t)direction {
    self = [super init];
    self.direction = direction;
    return self;
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
        CGRect new_frame;
        if(self.direction==LAYOUT_HORIZONTAL) {
            new_frame = CGRectMake(off,0,
                    new_size,
                    h);
        } else {
            new_frame = CGRectMake(0,off,
                    w,
                    new_size);
        }
        new_frame = CGRectInset(new_frame, [view getLLInset], [view getLLInset]);
        view.frame = new_frame;
        off+=new_size;
    }
}
@end

@interface ScrollingLinearLayout()
@property enum layout_dir_t direction;
@end

@implementation ScrollingLinearLayout {

}
-(instancetype)initWithDirection:(enum layout_dir_t)direction {
    self = [super init];
    self.direction = direction;
    return self;
}
-(void)layoutSubviews {
    float w = self.frame.size.width;
    float h = self.frame.size.height;
    float off = 0;
    // Accumulate weights
    float child_size = 0;
    for(UIView* view in self.subviews) {
        child_size  += [view getLLSize];
    }
    child_size = MAX(child_size, self.direction==LAYOUT_HORIZONTAL?w:h);
    if(self.direction==LAYOUT_HORIZONTAL) {
        self.contentSize = CGSizeMake(child_size,h);
    } else {
        self.contentSize = CGSizeMake(w,child_size);
    }
    for(UIView* view in self.subviews) {
        CGRect new_frame;
        float new_size = [view getLLSize];
        if(self.direction==LAYOUT_HORIZONTAL) {
            new_frame = CGRectMake(off,0,
                    new_size,
                    h);
        } else {
            new_frame = CGRectMake(0,off,
                    w,
                    new_size);
        }
        new_frame = CGRectInset(new_frame, [view getLLInset], [view getLLInset]);
        view.frame = new_frame;
        off+=new_size;
    }
}
@end