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

@interface meterViewController : UIViewController <UISplitViewControllerDelegate>
{
@public
    BOOL play;
    // A place to stash settings
    MeterSettings_t      meter_settings;
}

-(void)setDevice:(MooshimeterDevice*)device;

@property (strong, nonatomic) MooshimeterDevice *meter;

@property (strong, nonatomic) IBOutlet UILabel *Label0;
@property (strong, nonatomic) IBOutlet UILabel *Label1;
@property (strong, nonatomic) IBOutlet UILabel *CH1Label;
@property (strong, nonatomic) IBOutlet UILabel *CH2Label;
@property (strong, nonatomic) IBOutlet UILabel *CH1Raw;
@property (strong, nonatomic) IBOutlet UILabel *CH2Raw;

@end
