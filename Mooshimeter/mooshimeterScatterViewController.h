//
//  mooshimeterScatterViewController.h
//  Mooshimeter
//
//  Created by James Whong on 9/13/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "mooshimeter_device.h"

@interface mooshimeterScatterViewController : UIViewController <CPTPlotDataSource, UIAlertViewDelegate>
{
@public
    // A place to stash settings
    ADS1x9x_registers_t  ADC_settings;
    MeterSettings_t      meter_settings;
    double       time[      N_SAMPLE_BUFFER];
    double       ch1_values[N_SAMPLE_BUFFER];
    double       ch2_values[N_SAMPLE_BUFFER];
}

-(void)setDevice:(mooshimeter_device*)device;

@property (strong, nonatomic) mooshimeter_device *meter;

@property (strong, nonatomic) UITapGestureRecognizer *tapButton;

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTPlotSpace* space2; //remove this hack

@property (strong, nonatomic) UIAlertView *megaAlert;

@end
