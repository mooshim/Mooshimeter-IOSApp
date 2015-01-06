//
//  BLETIOADProgressViewController.h
//  TI BLE Multitool
//
//  Created by Ole Andreas Torvmark on 7/16/13.
//  Copyright (c) 2013 Ole Andreas Torvmark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLETIOADProfile.h"

@class BLETIOADProfile;

@interface BLETIOADProgressViewController : UIViewController

@property (strong,nonatomic) UIProgressView *progressBar;
@property (strong,nonatomic) UILabel *label1;
@property (strong,nonatomic) UILabel *label2;
@property (strong,nonatomic) BLETIOADProfile* oad_profile;

-(void) setupView;

@end
