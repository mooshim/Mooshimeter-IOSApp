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
#import "BaseVC.h"

@class LegacyMooshimeterDevice;
@class GraphSettingsView;

@interface XYPoint:NSObject
@property NSNumber *x,*y;
+(XYPoint*)make:(float)x y:(float)y;
+(XYPoint*)makeWithNSNumber:(NSNumber*)x y:(NSNumber*)y;
@end

@interface GraphVC : BaseVC <CPTPlotDataSource,MooshimeterDelegateProtocol,CPTPlotSpaceDelegate>

@property MooshimeterDeviceBase * meter;

@property (strong, nonatomic) UITapGestureRecognizer *tapButton;
@property (strong, nonatomic) CPTGraphHostingView *hostView;
@property (strong, nonatomic) CPTXYPlotSpace *leftAxisSpace, *rightAxisSpace;
@property (strong, nonatomic) UIButton* config_button;

// GUI config values

@property int max_points_onscreen;
@property bool xy_mode;
@property bool buffer_mode;
@property bool ch1_on;
@property bool ch2_on;
@property bool math_on;
@property bool autoscroll;

@property bool left_axis_auto;
@property bool right_axis_auto;

@property float sample_time;

// Data stashing

@property NSMutableArray<XYPoint*>* left_cache;
@property NSMutableArray<XYPoint*>* right_cache;

@property NSMutableArray<XYPoint*>* left_onscreen;
@property NSMutableArray<XYPoint*>* right_onscreen;

// Timer to prevent flooding
@property NSTimer* refresh_timer;
// Helper to keep track of what side of the graph is being touched (gets around issue with Coreplot
@property BOOL left_side_touched;

-(instancetype)initWithMeter:(MooshimeterDeviceBase*)meter;

@end
