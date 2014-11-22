//
//  GraphSettingsView.h
//  Mooshimeter
//
//  Created by James Whong on 11/16/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MooshimeterDevice.h"

@interface GraphSettingsView : UIView

@property (strong, nonatomic)UIButton* trend_or_burst_button;
@property (strong, nonatomic)UIButton* ch1_on_button;
@property (strong, nonatomic)UIButton* ch2_on_button;
@property (strong, nonatomic)UIButton* xy_on_button;

@end
