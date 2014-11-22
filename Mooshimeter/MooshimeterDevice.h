//
//  mooshimeter_device.h
//
//  James Whong 2013
//  All rights whatever
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "LGBluetooth.h"
#import "BLEUtility.h"
#import "MooshimeterProfileTypes.h"

#define BUILD_BUG_ON(condition) ((void)sizeof(char[1 - 2*!!(condition)]))
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

typedef void (^BufferDownloadCompleteCB)();
typedef struct {
    int8 high;      // Number of digits left of the decimal point
    uint8 n_digits; // Number of significant digits
} SignificantDigits;

@protocol MooshimeterDeviceDelegate <NSObject>
@required
-(void) finishedMeterSetup;
-(void) meterDisconnected;
@end

@interface MooshimeterDevice : NSObject <CBPeripheralDelegate>
{
    @public
    // These reflect actual values on the meter itself
    MeterSettings_t      meter_settings;
    MeterInfo_t          meter_info;
    MeterMeasurement_t   meter_sample;
    struct {
        int24_test                CH1_buf[N_ADC_SAMPLES];
        int24_test                CH2_buf[N_ADC_SAMPLES];
    } sample_buf;
    
    // These reflect values internal to the app that determine how to display the data
    bool oad_mode;
    
    BufferDownloadCompleteCB buffer_cb;
    BufferDownloadCompleteCB sample_cb;
    
    struct {
        BOOL ac_display[2];
        BOOL auto_range[2];
        BOOL raw_hex[2];
        BOOL channel_disp[2];
        BOOL burst_capture;
        BOOL xy_mode;
        BOOL rate_auto;
        BOOL depth_auto;
        enum : uint8 {
            CH3_VOLTAGE = 0,
            CH3_RESISTANCE,
            CH3_DIODE
        } ch3_mode;
    } disp_settings;
    @protected
}

@property (strong,nonatomic) LGPeripheral *p;
@property (strong,nonatomic) NSMutableDictionary* chars;
@property (strong,nonatomic) id <MooshimeterDeviceDelegate> delegate;

-(MooshimeterDevice*) init:(LGPeripheral*)periph delegate:(id<MooshimeterDeviceDelegate>)delegate;

-(void)connect;

-(void)reqMeterInfo:(LGCharacteristicReadCallback)cb;
-(void)reqMeterSettings:(LGCharacteristicReadCallback)cb;
-(void)reqMeterSample:(LGCharacteristicReadCallback)cb;

-(void)sendMeterSettings:(LGCharacteristicWriteCallback)cb;

-(void)enableStreamMeterSample:(BOOL)on cb:(LGCharacteristicNotifyCallback)cb update:(BufferDownloadCompleteCB)update;

-(void)enableStreamMeterBuf:(BOOL)on cb:(LGCharacteristicNotifyCallback)cb complete_buffer_cb:(BufferDownloadCompleteCB)complete_buffer_cb;

-(void)setMeterState:(int)new_state cb:(LGCharacteristicWriteCallback)cb;

-(void)setMeterLVMode:(bool)on cb:(LGCharacteristicWriteCallback)cb;
-(void)setMeterHVMode:(bool)on cb:(LGCharacteristicWriteCallback)cb;

-(int)getBufLen;

// These refer to the meter sample, which is calculated on the meter itself
-(double)getMean:(int)channel;
-(double)getRMS:(int)channel;
// These refer to the downloaded buffer
-(double)getBufMin:(int)channel;
-(double)getBufMax:(int)channel;
-(double)getBufMean:(int)channel;
-(double)getBufRMS:(int)channel;

-(double)getValAt:(int)channel i:(int)i;

-(NSString*)getDescriptor:(int)channel;
-(NSString*)getUnits:(int)channel;
-(NSString*)getInputLabel:(int)channel;

-(SignificantDigits)getSigDigits:(int)channel;

+(long)to_int32:(int24_test)arg;
+(int24_test)to_int24_test:(long)arg;

-(uint8)getChannelSetting:(int)ch;
-(void)setChannelSetting:(int)ch set:(uint8)set;

-(LGCharacteristic*)getLGChar:(uint16)UUID;

@end

extern MooshimeterDevice* g_meter;

