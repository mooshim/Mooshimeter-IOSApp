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
#import "GraphSettingsView.h"

#define N_POINTS_ONSCREEN 1024

@class MooshimeterDevice;

@protocol ScatterViewControllerDelegate <NSObject>
@required
-(void)handleScatterViewRotation;
@end

@interface GraphViewController : UIViewController <CPTPlotDataSource>
{
@public
    // A place to stash settings
    double       start_time;
    double       time[      N_POINTS_ONSCREEN];
    double       ch1_values[N_POINTS_ONSCREEN];
    double       ch2_values[N_POINTS_ONSCREEN];
    int          buf_i;
    int          buf_n;
    BOOL         play;
    BOOL         is_redrawing;
}

-(instancetype)initWithDelegate:(id<ScatterViewControllerDelegate>)delegate;

@property (strong, nonatomic) id<ScatterViewControllerDelegate> delegate;
@property (strong, nonatomic) UITapGestureRecognizer *tapButton;
@property (strong, nonatomic) CPTGraphHostingView *hostView;
@property (strong, nonatomic) CPTPlotSpace* space2; //remove this hack
@property (strong, nonatomic) UIButton* config_button;
@property (strong, nonatomic) GraphSettingsView* config_view;

@end
