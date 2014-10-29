//
//  mooshimeter_device.h
//
//  James Whong 2013
//  All rights whatever
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEUtility.h"

#import "MooshimeterProfileTypes.h"


#define BUILD_BUG_ON(condition) ((void)sizeof(char[1 - 2*!!(condition)]))

#define N_SAMPLE_BUFFER 256

/// Class which describes a mooshimeter
@interface mooshimeter_device : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    @public
    // These reflect actual values on the meter itself
    ADS1x9x_registers_t  ADC_settings;
    MeterSettings_t      meter_settings;
    MeterInfo_t          meter_info;
    MeterMeasurement_t   meter_sample;
    struct {
        int24_test                CH1_buf[N_SAMPLE_BUFFER];
        int24_test                CH2_buf[N_SAMPLE_BUFFER];
    } sample_buf;
    unsigned char        cal_i;
    unsigned short       buf_i;
    
    // These reflect values internal to the app that determine how to display the data
    struct {
        BOOL connected;
        BOOL ch1Off;
        BOOL ch2Off;
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

-(void)setup:(id)target cb:(SEL)cb arg:(id)arg;
-(void)reconnect:(id)target cb:(SEL)cb arg:(id)arg;
-(void)disconnect;

-(void)reqADCSettings:(id)target cb:(SEL)cb arg:(id)arg;
-(void)sendADCSettings:(id)target cb:(SEL)cb arg:(id)arg;
-(void)reqMeterSettings:(id)target cb:(SEL)cb arg:(id)arg;
-(void)sendMeterSettings:(id)target cb:(SEL)cb arg:(id)arg;

-(void)reqMeterInfo:(id)target cb:(SEL)cb arg:(id)arg;

//-(void)doCal:(id)target cb:(SEL)cb arg:(id)arg;

-(void)reqMeterSample:(id)target cb:(SEL)cb arg:(id)arg;
-(void)startStreamMeterSample:(id)target cb:(SEL)cb arg:(id)arg;
-(void)stopStreamMeterSample;

-(void)enableStreamMeterBuf:(id)target cb:(SEL)cb arg:(id)arg;
-(void)disableStreamMeterBuf;

-(void)setBufferReceivedCallback:(id)target cb:(SEL)cb arg:(id)arg;

-(void)setMeterState:(int)new_state target:(id)target cb:(SEL)cb arg:(id)arg;
-(int)getMeterState;

-(void)setMeterLVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg;
-(void)setMeterHVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg;

-(void)registerDisconnectCB:(id)target cb:(SEL)cb arg:(id)arg;

-(int)getBufLen;

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
-(double)getCH1BufAvg;
-(double)getCH2BufAvg;

-(int)getBufAvg:(int24_test*)arg;

-(long)to_int32:(int24_test)arg;

-(int24_test)to_int24_test:(long)arg;

@end

