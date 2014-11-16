//
//  mooshimeterDetailViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEUtility.h"
#import "MooshimeterDevice.h"
#import "ScatterViewController.h"
#import "ChannelView.h"

@class ChannelView;

@interface MeterViewController : UIViewController <UISplitViewControllerDelegate>
{
@public
    BOOL play;
    // A place to stash settings
    MeterSettings_t      meter_settings;
}
@property (strong, nonatomic) ChannelView* ch1_view;
@property (strong, nonatomic) ChannelView* ch2_view;
@property (strong, nonatomic) UIButton* rate_auto_button;
@property (strong, nonatomic) UIButton* rate_button;
@property (strong, nonatomic) UIButton* depth_auto_button;
@property (strong, nonatomic) UIButton* depth_button;
@property (strong, nonatomic) UIButton* logging_button;
@property (strong, nonatomic) UIButton* logging_settings_button;

+(void)style_auto_button:(UIButton*)b on:(BOOL)on;
+(NSString*) formatReading:(double)val digits:(SignificantDigits)digits;

@end
