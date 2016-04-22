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
