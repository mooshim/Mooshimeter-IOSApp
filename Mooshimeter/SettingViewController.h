//
//  mooshimeterDetailViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MooshimeterDevice.h"

@interface SettingViewController : UIViewController

-(void)setDevice:(MooshimeterDevice*)device;

@property (strong, nonatomic) MooshimeterDevice *meter;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;


@property (strong, nonatomic) IBOutlet UIButton *CalButton;
@property (strong, nonatomic) IBOutlet UIButton *CH1Button;
@property (strong, nonatomic) IBOutlet UIButton *CH2Button;
@property (strong, nonatomic) IBOutlet UIButton *RateButton;
@property (strong, nonatomic) IBOutlet UIButton *NameButton;

@end
