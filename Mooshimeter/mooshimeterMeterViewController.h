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

@interface mooshimeterMeterViewController : UIViewController <UISplitViewControllerDelegate>
{
@public
    BOOL play;
    // A place to stash settings
    MeterSettings_t      meter_settings;
}

-(void)setDevice:(mooshimeter_device*)device;

@property (strong, nonatomic) mooshimeter_device *meter;

@property (strong, nonatomic) IBOutlet UILabel *Label0;
@property (strong, nonatomic) IBOutlet UILabel *Label1;
@property (strong, nonatomic) IBOutlet UILabel *CH1Label;
@property (strong, nonatomic) IBOutlet UILabel *CH2Label;
@property (strong, nonatomic) IBOutlet UILabel *CH1Raw;
@property (strong, nonatomic) IBOutlet UILabel *CH2Raw;

@end
