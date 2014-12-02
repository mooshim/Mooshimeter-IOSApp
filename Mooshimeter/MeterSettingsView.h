//
//  SettingsViewController.h
//  Mooshimeter
//
//  Created by James Whong on 11/30/14.
//  Copyright (c) 2014 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MooshimeterDevice.h"

@interface MeterSettingsView : UIView <UITextFieldDelegate,UIAlertViewDelegate>

@property (strong,nonatomic) UITextField*           name_control;
@property (strong,nonatomic) UISegmentedControl*    logging_period_control;
@property (strong,nonatomic) UITextField*           logging_time_control;
@property (strong,nonatomic) UIButton*              hibernateButton;

@end
