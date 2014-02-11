//
//  MooshimeterProfileTypes.h
//  Mooshimeter
//
//  Created by James Whong on 11/26/13.
//  Copyright (c) 2013 mooshim. All rights reserved.
//

#ifndef Mooshimeter_MooshimeterProfileTypes_h
#define Mooshimeter_MooshimeterProfileTypes_h

#define METER_NAME_LEN 16

#ifdef __IAR_SYSTEMS_ICC__
#include "int24.h"
#else
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned long uint32;

typedef signed char int8;
typedef signed short int16;
typedef signed long int32;

typedef union {
    char bytes[3];
} int24_test;
#endif

typedef enum
#ifndef __IAR_SYSTEMS_ICC__
: uint8
#endif
{
    METER_SHUTDOWN=0,   // Booting from power down.
    METER_STANDBY,      // uC sleeping, ADC powered down
    METER_PAUSED,       // uC active, ADC active, not sampling
    METER_RUNNING,      // uC active, ADC active, sampling until buffer is full, then performing computations and repeating
    METER_ONESHOT,      // uC active, ADC active, sampling until buffer is full, performing computations and dropping back to METER_PAUSED
    METER_CALIBRATING,  // uC active, ADC active, uC will override user ADC settings to run a cal routine and drop back to METER_PAUSED when finished
} meter_state_t;

typedef struct {
    uint8 cal_target :7; // Specify which calibration slot to use in flash
    uint8 save       :1; // Set a 1 here to save to flash
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
cal_setting_t;

typedef struct {
    uint8 source         : 4;   // 0: no trigger, 1: ch1, 2: ch2.
    uint8 edge           : 3;   // 0: rising, 1: falling, 2: either
    uint8 cont           : 1;   // 0: one shot, 1: continuous
    signed long crossing;       // Value at which to trigger
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
trigger_settings_t;

typedef struct {
    uint8 pcb_version;
    uint8 assembly_variant;
    uint16 lot_number;
    uint32 fw_version;
    uint32 programming_utc_time;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterInfo_t;

typedef struct {
    int24_test ch1_offset;
    int24_test ch2_offset;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterOffsets_t;

typedef struct {
    MeterOffsets_t internal_short;
    MeterOffsets_t electrodes_gain0;
    MeterOffsets_t electrodes_gain1;
    MeterOffsets_t ch3_pulldown;
    MeterOffsets_t ch3_floating;
    MeterOffsets_t ps_and_temp;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterCalPoint_t;

typedef struct {
    meter_state_t target_meter_state;    // The target state of the meter
    meter_state_t present_meter_state;   // The state of the meter right now.  Read only.
    cal_setting_t cal_setting;           // Specifies the buffer in to which the result of the calibration will be written
    trigger_settings_t trigger_settings; // Specifies level and rising/falling edge for pause (UNUSED)
    uint8 buf_depth_log2 : 4;            // Determines how deep a sample buffer to capture and average.  Depth = 2^(buf_depth_log2)
    uint8 calc_mean      : 1;            // Flag.  True = means are calculated and chx_reading_lsb in MeterMeasurement_t is populated
    uint8 calc_ac        : 1;            // Flag.  True = mean squares are calculated and ac_chx_ms in MeterMeasurement_t is populated
    uint8 calc_freq      : 1;            // Flag.  True = ch2_period in MeterMeasurement_t is populated
    uint8 fill           : 1;            // Ignored.
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
MeterSettings_t;

typedef struct {
    int24_test ch1_reading_lsb; // Mean of the sample buffer
    int24_test ch2_reading_lsb; // Mean of the sample buffer
    uint32 ac_ch1_ms;           // Mean-square of the sample buffer (TODO)
    uint32 ac_ch2_ms;           // Mean-square of the sample buffer (TODO)
    uint16 ch2_period;          // Period of the signal in the sample buffer (fixed point, 8 bits integral, 8 bits fractional) (TODO)
    int16 power_factor;         // Power factor, fixed point, 16 bits fractional (TODO)
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
MeterMeasurement_t;

#ifndef __IAR_SYSTEMS_ICC__
typedef struct {
    uint8 id;                   // Information on these registers can be found on the ADS1292 datasheet.
    uint8 config1;
    uint8 config2;
    uint8 loff;
    uint8 ch1set;
    uint8 ch2set;
    uint8 rld_sens;
    uint8 loff_sens;
    uint8 loff_stat;
    uint8 resp1;
    uint8 resp2;
    uint8 gpio;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
ADS1x9x_registers_struct_t;

typedef union {
    ADS1x9x_registers_struct_t str;
    uint8 bytes[sizeof(ADS1x9x_registers_struct_t)];
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
ADS1x9x_registers_t;
#endif

#endif
