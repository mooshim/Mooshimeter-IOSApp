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

typedef signed char int8;
typedef signed short int16;

// XCode 64 bit transition makes longs 8 bytes wide
// But IAR for 8051 calls int 2 bytes wide, so we need some compiler
// specific switches
#ifndef __IAR_SYSTEMS_ICC__
typedef unsigned int uint32;
typedef signed int int32;
#else
typedef unsigned long uint32;
typedef signed long int32;
#endif

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
    METER_STANDBY,      // uC sleeping, ADC powered down.  Wakes to advertise occasionally.
    METER_PAUSED,       // uC active, ADC active, not sampling
    METER_RUNNING,      // uC active, ADC active, sampling until buffer is full, then performing computations and repeating
    METER_ONESHOT,      // uC active, ADC active, sampling until buffer is full, performing computations and dropping back to METER_PAUSED
    METER_ZERO,         // uC active, ADC active, override factory programmed zero setting 
    METER_TEMPREAD,
    METER_CALIBRATING,  // uC active, ADC active, uC will override user ADC settings to run a cal routine and drop back to METER_PAUSED when finished
} meter_state_t;


typedef struct {
    //uint8 source         : 4;   // 0: no trigger, 1: ch1, 2: ch2.
    //uint8 edge           : 3;   // 0: rising, 1: falling, 2: either
    //uint8 cont           : 1;   // 0: one shot, 1: continuous
    uint8 setting;  // XCode is not playing nicely with bit fields.
    int32 crossing;       // Value at which to trigger
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

/*
* Signal chains include: 
* WORLD -> 10M DIVIDER -> PGA -> ADC
* WORLD -> 1mOhm SENSE RES -> CURRENT SENSE AMP -> PGA -> ADC
* WORLD -> PGA -> ADC
*
* We can get PGA and ADC gain by putting known voltage on CH3 and mapping
* Ch1 and CH2 to it.  Then we can get the divider ratios by applying known test
* current and voltages.
*
* Calibration stage 1: Determine intrinsic offsets  
*   Short ACTIVE to COMMON
*   Map CH1 and CH2 to ACTIVE
*   For each PGA gain, determine the offset and populate intrinsic_offsets
* Stage 2:  Determine extrinsic offsets
*   We can assume that the voltage divider applies no extrinsic offset
*   We cannot assume the same for the current sense amp
*   Disconnect all terminals
*   Map CH1 to CH1 and CH2 to CH2
*   Sample current, remove intrinsic offset, store extrinsic offset
* Stage 3:  Determine intrinsic gains
*   Apply 50mV from ACTIVE to COMMON
*   Map CH1 and CH2 to ACTIVE
*   For each PGA gain, determine the gain error and populate intrinsic_gains
* Stage 4:  Determine extrinsic gains
*   Apply 100mA test current and 5V test voltage
*   Sample CH1, calculate current gain
*   Sample CH2 at 60V setting, calculate voltage divider gain
*   Sample CH2 at 600V setting, calculate voltage divider gain
*/

// The 7 indices refer to the 7 possible PGA settings
typedef struct {
  uint16 cal_temp;
  int16 ch1_intrinsic_offsets[7];
  int16 ch2_intrinsic_offsets[7];
  int16 ch1_intrinsic_gain[7];
  int16 ch2_intrinsic_gain[7];
  int16 isns_offset;
  int16 ch1_isns_gain;
  int16 ch2_60v_gain;
  int16 ch2_600v_gain;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterFactoryCal_t;

// The values in this structure are changed as the meter settings
// are changed.
typedef struct {
  int16 ch1_offset;
  int16 ch2_offset;
  uint16 ch1_gain;  // Fixed point, 1 integer digit
  uint16 ch2_gain;  // Fixed point, 1 integer digit
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterCalPoint_t;

#define METER_MEASURE_SETTINGS_ISRC_ON         0x01
#define METER_MEASURE_SETTINGS_ISRC_LVL        0x02
#define METER_MEASURE_SETTINGS_ACTIVE_PULLDOWN 0x04

#define METER_CALC_SETTINGS_DEPTH_LOG2 0x0F
#define METER_CALC_SETTINGS_MEAN       0x10
#define METER_CALC_SETTINGS_AC         0x20
#define METER_CALC_SETTINGS_FREQ       0x40

typedef struct {
    meter_state_t target_meter_state;    // The target state of the meter
    meter_state_t present_meter_state;   // The state of the meter right now.  Read only.
    trigger_settings_t trigger_settings; // Specifies level and rising/falling edge for pause (UNUSED)
    uint8 measure_settings;              // Specifies features to turn on and off.  Note that voltage gain is controlled through ADC settings
    uint8 calc_settings;                 // Specifies what analysis to run on captured data
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

#define ADS1x9x_MANDATORY_BITS {\
  0x10, \
  0x00, \
  0x80, \
  0x10, \
  0x00, \
  0x00, \
  0x00, \
  0x00, \
  0x00, \
  0x02, \
  0x01, \
  0x00, \
}

#define ADS1x9x_MANDATORY_BITS_MASK {\
  0x1C, \
  0x78, \
  0x84, \
  0x12, \
  0x00, \
  0x00, \
  0x00, \
  0xC0, \
  0xA0, \
  0x02, \
  0x79, \
  0xF0, \
}

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
