//
//  ChannelView.h
//  Mooshimeter
//
//  Created by James Whong on 11/9/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MooshimeterDevice.h"
#import "MeterViewController.h"

@interface ChannelView : UIView {
    @public
        NSInteger      channel;
}

-(instancetype)initWithFrame:(CGRect)frame ch:(NSInteger)ch;
-(void)value_label_refresh;
-(void)refreshAllControls;

@property (strong,nonatomic) UILabel*  value_label;
@property (strong,nonatomic) UIButton* units_button;
@property (strong,nonatomic) UIButton* display_set_button;
@property (strong,nonatomic) UIButton* input_set_button;
@property (strong,nonatomic) UIButton* auto_manual_button;
@property (strong,nonatomic) UIButton* range_button;

@end
