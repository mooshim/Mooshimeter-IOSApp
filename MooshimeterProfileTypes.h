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


#ifndef Mooshimeter_MooshimeterProfileTypes_h
#define Mooshimeter_MooshimeterProfileTypes_h

#define BUILD_BUG_ON(condition) ((void)sizeof(char[1 - 2*!!(condition)]))

#ifndef __IAR_SYSTEMS_ICC__
#define LO_UINT16(i) ((i   ) & 0xFF)
#define HI_UINT16(i) ((i>>8) & 0xFF)
#endif

#define MOOSHIM_BASE_UUID_128( uuid )  0xd4, 0xdb, 0x05, 0xe0, 0x54, 0xf2, 0x11, 0xe4, \
                                  0xab, 0x62, 0x00, 0x02, LO_UINT16( uuid ), HI_UINT16( uuid ), 0xc5, 0x1b                                   

#define METER_SERVICE_UUID  0xFFA0
#define METER_INFO          0xFFA1
#define METER_NAME          0xFFA2
#define METER_SETTINGS      0xFFA3
#define METER_LOG_SETTINGS  0xFFA4
#define METER_UTC_TIME      0xFFA5
#define METER_SAMPLE        0xFFA6
#define METER_CH1BUF        0xFFA7
#define METER_CH2BUF        0xFFA8
#define METER_CAL           0xFFA9
#define METER_LOG_DATA      0xFFAA
#define METER_TEMP          0xFFAB
#define METER_BAT           0xFFAC

#define METER_SERIN         0xFFA1
#define METER_SEROUT        0xFFA2

#define OAD_SERVICE_UUID    0xFFC0
#define OAD_IMAGE_NOTIFY    0xFFC1
#define OAD_IMAGE_BLOCK_REQ 0xFFC2
#define OAD_REBOOT          0xFFC3

#define N_ADC_SAMPLES_LOG2 8
#define N_ADC_SAMPLES      (1<<N_ADC_SAMPLES_LOG2)

typedef enum {
    CH1=0,
    CH2,
    MATH,
} Channel;


#ifdef __IAR_SYSTEMS_ICC__
#include "int24.h"
#else
typedef unsigned char uint8;
typedef unsigned short uint16;

typedef signed char int8;
typedef signed short int16;

typedef union {
    char bytes[3];
} int24_test;
#endif

// XCode 64 bit transition makes longs 8 bytes wide
// But IAR for 8051 calls int 2 bytes wide, so we need some compiler
// specific switches
#ifndef __IAR_SYSTEMS_ICC__
typedef unsigned int uint32;
typedef signed int int32;
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
    METER_HIBERNATE,    // uC sleeping, radio off.  Wake up to test if inputs are shorted, and if they are reboot.
} meter_state_t;

typedef enum
#ifndef __IAR_SYSTEMS_ICC__
: uint8
#endif
{
  LOGGING_OFF=0,
  LOGGING_READY,
  LOGGING_ACTIVE,
  LOGGING_SAMPLING,
  LOGGING_ASLEEP
} logging_state_t;

typedef enum 
#ifndef __IAR_SYSTEMS_ICC__
: uint8
#endif
{
  LOGGING_OK=0,
  LOGGING_NO_MEDIA,
  LOGGING_MOUNT_FAIL,
  LOGGING_INSUFFICIENT_SPACE,
  LOGGING_WRITE_ERROR,
  LOGGING_END_OF_FILE,
} logging_error_t;

#define TRIGGER_SETTING_SRC_OFF      (0x00)
#define TRIGGER_SETTING_SRC_CH1      (0x01)
#define TRIGGER_SETTING_SRC_CH2      (0x02)
#define TRIGGER_SETTING_EDGE_RISING  (0x00 <<2)
#define TRIGGER_SETTING_EDGE_FALLING (0x01 <<2) 
#define TRIGGER_SETTING_EDGE_EITHER  (0x02 <<2)

typedef struct {
    uint8      setting;        
    uint16     x_offset;       // TODO: x offset for the trigger point to rest at
    int24_test crossing;       // Value at which to trigger
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
trigger_settings_t;

typedef struct {
    uint8 pcb_version;
    uint8 assembly_variant;
    uint16 lot_number;
    uint32 build_time;
    uint8 reserved[12];
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterInfo_t;

// The 7 indices refer to the 7 possible PGA settings
// The gains below are 16 bit fixed point values representing a number
// between 0 and 2
typedef struct {
  uint32 build_time;
  uint16 cal_temp;
  int16 ch_offsets[2][7];   // This contains CH2 in low voltage mode gpio=0x01
  int16 ch2_hv_offsets[7];
  int16 ch_3_offsets[2][7];
  uint16 ch_gain[2][7];     // Gains are fixed point between 0 and 2
  uint16 ch1_isns_gain;
  uint16 ch2_60v_gain;
  uint16 ch2_600v_gain;
  uint16 ch2_100na_gain;
  uint16 ch2_100ua_gain;
  uint16 __pad;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed))
#endif
MeterFactoryCal_t;

#define METER_MEASURE_SETTINGS_ISRC_ON         0x01
#define METER_MEASURE_SETTINGS_ISRC_LVL        0x02
#define METER_MEASURE_SETTINGS_ACTIVE_PULLDOWN 0x04

#define METER_CALC_SETTINGS_DEPTH_LOG2 0x0F
#define METER_CALC_SETTINGS_MEAN       0x10
#define METER_CALC_SETTINGS_ONESHOT    0x20
#define METER_CALC_SETTINGS_MS         0x40
#define METER_CALC_SETTINGS_RES        0x80

#define ADC_SETTINGS_SAMPLERATE_MASK 0x07
#define ADC_SETTINGS_GPIO_MASK 0x30

#define METER_CH_SETTINGS_PGA_MASK 0x70
#define METER_CH_SETTINGS_INPUT_MASK 0x0F

typedef struct {
  struct {
    meter_state_t present_meter_state;   // The state of the meter right now.
  } ro;
  struct {
    meter_state_t target_meter_state;    // The target state of the meter
    trigger_settings_t trigger_settings; // Trigger control
    uint8 measure_settings;              // Specifies features to turn on and off.  Note that voltage gain is controlled through ADC settings
    uint8 calc_settings;                 // Specifies what analysis to run on captured data
    uint8 chset[2];
    uint8 adc_settings;
  } rw;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
MeterSettings_t;

typedef struct {
  struct {
    uint8 sd_present;
    logging_state_t present_logging_state;
    logging_error_t logging_error;
    uint16 file_number;                    // The log file number.  A new record is started every logging session.
    uint32 file_offset;                    // The offset within the file that is being written to (when logging) or read from (when streaming out)
  }
#ifndef __IAR_SYSTEMS_ICC__
    __attribute__((packed))
#endif
  ro;
  struct {
    logging_state_t  target_logging_state;        
    uint16 logging_period_ms;              // How long to wait between taking log samples
    uint32 logging_n_cycles;               // How many samples to take before sleeping forever
  }
#ifndef __IAR_SYSTEMS_ICC__
    __attribute__((packed))
#endif
  rw;
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
MeterLogSettings_t;

typedef struct {
    int24_test ch_reading_lsb[2]; // Mean of the sample buffer
    float ch_ms[2];       // Mean square of the buffer.  Square root it on the other size.
}
#ifndef __IAR_SYSTEMS_ICC__
__attribute__((packed)) 
#endif
MeterMeasurement_t;

#endif
