/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "LegacyMooshimeterDevice.h"
#import "GraphSettingsView.h"

#define N_POINTS_ONSCREEN 1024

@class LegacyMooshimeterDevice;

@protocol ScatterViewControllerDelegate <NSObject>
@required
-(void)switchToMeterView;
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
