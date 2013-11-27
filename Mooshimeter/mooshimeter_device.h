//
//  mooshimeter_device.h
//
//  James Whong 2013
//  All rights whatever
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEUtility.h"

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned long uint32;

typedef signed char int8;
typedef signed short int16;
typedef signed long int32;

typedef union {
    char bytes[3];
} int24;

typedef enum : uint8 {
    METER_SHUTDOWN=0,
    METER_STANDBY,
    METER_PAUSED,
    METER_RUNNING,
    METER_ONESHOT,
    METER_CALIBRATING,
} meter_state_t;

typedef struct {
    uint8 cal_target :7;
    uint8 save       :1;
}__attribute__((packed)) cal_setting_t;

typedef struct {
    uint8 source         : 4;   // 0: no trigger, 1: ch1, 2: ch2.
    uint8 edge           : 3;   // 0: rising, 1: falling, 2: either
    uint8 cont           : 1;   // 0: one shot, 1: continuous
    signed long crossing;       // Value at which to trigger
}__attribute__((packed)) trigger_settings_t;

typedef struct {
    uint8 pcb_version;
    uint8 assembly_variant;
    uint16 lot_number;
    uint32 fw_version;
    uint32 programming_utc_time;
}__attribute__((packed)) MeterInfo_t;

typedef struct {
    int24 ch1_offset;
    int24 ch2_offset;
}__attribute__((packed)) MeterOffsets_t;

typedef struct {
    MeterOffsets_t internal_short;
    MeterOffsets_t electrodes_gain0;
    MeterOffsets_t electrodes_gain1;
    MeterOffsets_t ch3_pulldown;
    MeterOffsets_t ch3_floating;
    MeterOffsets_t ps_and_temp;
}__attribute__((packed)) MeterCalPoint_t;

typedef struct {
    meter_state_t target_meter_state;
    meter_state_t present_meter_state;
    cal_setting_t cal_setting;           // Specifies the buffer in to which the result of the calibration will be written
    trigger_settings_t trigger_settings;
    uint8 buf_depth_log2 : 4;
    uint8 calc_mean      : 1;
    uint8 calc_ac        : 1;
    uint8 calc_freq      : 1;
    uint8 fill           : 1;
}__attribute__((packed)) MeterSettings_t;

typedef struct {
    int24 ch1_reading_lsb;
    int24 ch2_reading_lsb;
    uint32 ac_ch1_ms;
    uint32 ac_ch2_ms;
    uint16 ch2_period;
    int16 power_factor;
}__attribute__((packed)) MeterMeasurement_t;

typedef struct {
    uint8 id;
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
}__attribute__((packed)) ADS1x9x_registers_struct_t;

typedef union {
    ADS1x9x_registers_struct_t str;
    uint8 bytes[sizeof(ADS1x9x_registers_struct_t)];
} ADS1x9x_registers_t;

#define BUILD_BUG_ON(condition) ((void)sizeof(char[1 - 2*!!(condition)]))

#define N_SAMPLE_BUFFER 128

/// Class which describes a mooshimeter
@interface mooshimeter_device : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    @public
    // These reflect actual values on the meter itself
    ADS1x9x_registers_t  ADC_settings;
    MeterSettings_t      meter_settings;
    MeterCalPoint_t      meter_cal[7];
    MeterInfo_t          meter_info;
    MeterMeasurement_t   meter_sample;
    struct {
        int24                CH1_buf[N_SAMPLE_BUFFER];
        int24                CH2_buf[N_SAMPLE_BUFFER];
    } sample_buf;
    unsigned char        cal_i;
    unsigned short       buf_i;
    
    // These reflect values internal to the app that determine how to display the data
    struct {
        BOOL xy_mode;
        enum : uint8 {
            CH3_VOLTAGE = 0,
            CH3_RESISTANCE,
            CH3_DIODE
        } ch3_mode;
    } disp_settings;
    @protected
}

@property (strong,nonatomic)   CBPeripheral *p;
@property (strong,nonatomic)   CBCentralManager *manager;
@property (strong,nonatomic)   NSMutableDictionary *cbs;

-(mooshimeter_device*) init:manager periph:(CBPeripheral*)periph;
-(void)sync;

-(void)setup:(id)target cb:(SEL)cb arg:(id)arg;
-(void)disconnect:(id)target cb:(SEL)cb arg:(id)arg;

-(void)reqADCSettings:(id)target cb:(SEL)cb arg:(id)arg;
-(void)sendADCSettings:(id)target cb:(SEL)cb arg:(id)arg;
-(void)reqMeterSettings:(id)target cb:(SEL)cb arg:(id)arg;
-(void)sendMeterSettings:(id)target cb:(SEL)cb arg:(id)arg;

-(void)reqMeterInfo:(id)target cb:(SEL)cb arg:(id)arg;

-(void)reqSampleBuffer:(id)target cb:(SEL)cb arg:(id)arg;
-(void)reqCalPoint:(int)i target:(id)target cb:(SEL)cb arg:(id)arg;
-(void)doCal:(id)target cb:(SEL)cb arg:(id)arg;
-(void)saveCalToNV:(int)i target:(id)target cb:(SEL)cb arg:(id)arg;

-(void)reqMeterSample:(id)target cb:(SEL)cb arg:(id)arg;
-(void)startStreamMeterSample:(id)target cb:(SEL)cb arg:(id)arg;
-(void)stopStreamMeterSample;

-(void)downloadSampleBuffer:(id)target cb:(SEL)cb arg:(id)arg;

-(void)setMeterState:(int)new_state target:(id)target cb:(SEL)cb arg:(id)arg;
-(int)getMeterState;

-(void)setMeterHVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg;
-(void)setMeterCH3PullDown:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg;

-(void)registerDisconnectCB:(id)target cb:(SEL)cb arg:(id)arg;

-(MeterMeasurement_t)getCalibratedValues;
-(double)getCH1Value;
-(double)getCH1Value:(int)index;
-(double)getCH1ACValue;
-(NSString*)getCH1Label;
-(NSString*)getCH1Units;
-(double)getCH2Value;
-(double)getCH2Value:(int)index;
-(double)getCH2ACValue;
-(NSString*)getCH2Label;
-(NSString*)getCH2Units;

-(double)getCH1BufMin;
-(double)getCH2BufMin;

-(double)getCH1BufMax;
-(double)getCH2BufMax;

+(long)to_int32:(int24)arg;

+(int24)to_int24:(long)arg;

@end

