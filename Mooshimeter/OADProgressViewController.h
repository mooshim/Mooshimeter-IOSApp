//
//  OADViewController.h
//  TI BLE Multitool
//
//  Created by Ole Andreas Torvmark on 7/16/13.
//  Copyright (c) 2013 Ole Andreas Torvmark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OADProfile.h"
#import "OADDevice.h"
#import "BaseVC.h"

@class OADProfile;

@interface OADViewController : BaseVC <MooshimeterDelegateProtocol>

@property (strong,nonatomic) UIProgressView *progressBar;
@property (strong,nonatomic) UILabel *percent_label;
@property (strong,nonatomic) UILabel *timing_label;
@property (strong,nonatomic) UIButton* upload_button;
@property (strong, nonatomic) UITextView *terminal;

@property (strong,nonatomic) OADProfile* oad_profile;
@property OADDevice* meter;
@property void(^async_block)();


- (instancetype)initWithMeter:(MooshimeterDeviceBase*)meter;
-(void) setupView;

@end
