//
//  ChannelView.h
//  Mooshimeter
//
//  Created by James Whong on 11/9/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MooshimeterDevice.h"

@interface ChannelView : UIView {
    @public
        NSInteger      channel;
}

-(ChannelView*)initWithFrame:(CGRect)frame;

@property (strong,nonatomic) UILabel*  value_label;
@property (strong,nonatomic) UILabel*  units_label;
@property (strong,nonatomic) UIButton* display_set_button;
@property (strong,nonatomic) UIButton* input_set_button;
@property (strong,nonatomic) UIButton* auto_manual_button;
@property (strong,nonatomic) UIButton* range_button;

@end
