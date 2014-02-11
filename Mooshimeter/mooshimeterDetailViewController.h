//
//  mooshimeterDetailViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/3/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEUtility.h"
#import "mooshimeter_device.h"
#import "mooshimeterScatterViewController.h"

@interface mooshimeterDetailViewController : UIViewController <UISplitViewControllerDelegate>
{
@public
    BOOL play;
    // A place to stash settings
    ADS1x9x_registers_t  ADC_settings;
    MeterSettings_t      meter_settings;
}

-(void)setDevice:(mooshimeter_device*)device;

@property (strong, nonatomic) mooshimeter_device *meter;

@property (weak, nonatomic) IBOutlet UILabel *Label0;
@property (weak, nonatomic) IBOutlet UILabel *Label1;
@property (weak, nonatomic) IBOutlet UILabel *WattLabel;
@property (weak, nonatomic) IBOutlet UILabel *CH1Label;
@property (weak, nonatomic) IBOutlet UILabel *CH2Label;

@end
