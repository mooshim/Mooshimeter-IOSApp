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

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "LGBluetooth.h"
#import "BLEUtility.h"
#import "MooshimeterProfileTypes.h"
#import "MooshimeterDeviceBase.h"

#define BUILD_BUG_ON(condition) ((void)sizeof(char[1 - 2*!!(condition)]))
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

@interface LegacyMooshimeterDevice : MooshimeterDeviceBase
{
    @public
    // These reflect actual values on the meter itself
    MeterSettings_t      meter_settings;
    MeterLogSettings_t   meter_log_settings;
    MeterInfo_t          meter_info;
    MeterMeasurement_t   meter_sample;
    struct {
        int24_test                CH1_buf[N_ADC_SAMPLES];
        int24_test                CH2_buf[N_ADC_SAMPLES];
    } sample_buf;
    
    // These reflect values internal to the app that determine how to display the data
    float offsets[2];
    float bat_voltage;
    Chooser* input_descriptors[3];
}

@end

