//
//  mooshimeterScatterViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/13/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "MooshimeterDevice.h"

@class MooshimeterDevice;

@interface ScatterViewController : UIViewController <CPTPlotDataSource, UIAlertViewDelegate>
{
@public
    // A place to stash settings
    MeterSettings_t      meter_settings;
    double       time[      N_ADC_SAMPLES];
    double       ch1_values[N_ADC_SAMPLES];
    double       ch2_values[N_ADC_SAMPLES];
}

-(void)setDevice:(MooshimeterDevice*)device;

@property (strong, nonatomic) MooshimeterDevice *meter;

@property (strong, nonatomic) UITapGestureRecognizer *tapButton;

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTPlotSpace* space2; //remove this hack

@property (strong, nonatomic) UIAlertView *megaAlert;

@end
