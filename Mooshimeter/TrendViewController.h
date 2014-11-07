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

#define N_POINTS_ONSCREEN 512

@interface TrendViewController : UIViewController <CPTPlotDataSource>
{
@public
    double       start_time;
    
    float        poll_pause;
    double       time[N_POINTS_ONSCREEN];
    double       ch1_values[N_POINTS_ONSCREEN];
    double       ch2_values[N_POINTS_ONSCREEN];
    int          buf_i;
    int          buf_n;
    BOOL         play;
    BOOL         is_redrawing;
    
    // A place to stash settings
    MeterSettings_t      meter_settings;
@protected
}

-(void)setDevice:(MooshimeterDevice*)device;

@property (strong, nonatomic) MooshimeterDevice *meter;

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTPlotSpace* space2; //remove this hack

@property (strong, nonatomic) UITapGestureRecognizer *pauseButton;

@end
