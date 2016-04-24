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

#import "LegacyMooshimeterDevice.h"
#import "oad.h"

typedef enum {
    NATIVE,
    TEMP,
    AUX_V,
    RESISTANCE,
    DIODE,
}INPUT_MODE;
typedef enum {
    PGA_GAIN_1,
    PGA_GAIN_4,
    PGA_GAIN_12,
    PGA_IGNORE,
} PGA_GAIN;
typedef enum {
    GPIO0,
    GPIO1,
    GPIO2,
    GPIO3,
    GPIO_IGNORE,
} GPIO_SETTING;
typedef enum {
    ISRC_OFF,
    ISRC_LOW,
    ISRC_MID,
    ISRC_HIGH,
    ISRC_IGNORE,
} ISRC_SETTING;

typedef float (^Lsb2NativeConverter)(int lsb);

@interface myRangeDescriptor:RangeDescriptor
@property (atomic, assign) char chset;
@property (atomic, assign) GPIO_SETTING gpio;
@property (atomic, assign) ISRC_SETTING isrc;
@property (atomic, strong) Lsb2NativeConverter converter;
@end
@implementation myRangeDescriptor
-(id)init {
    self = [super init];
    self.chset = 0;
    self.gpio=GPIO_IGNORE;
    self.isrc=ISRC_IGNORE;
    self.converter=^Lsb2NativeConverter{
        return 0;
    };
    return self;
}
@end

@interface myInputDescriptor:InputDescriptor
@property (atomic,assign) INPUT_MODE input;
@property (atomic,assign) bool is_ac;
-(id) initWithName:(NSString*)name units:(NSString*)units input:(INPUT_MODE)input is_ac:(bool)is_ac;
-(void) addRange:(NSString*)name converter:(Lsb2NativeConverter)conv max:(float)max gain:(PGA_GAIN)gain gpio:(GPIO_SETTING)gpio isrc:(ISRC_SETTING)isrc;
@end
@implementation myInputDescriptor
-(id) initWithName:(NSString*)name units:(NSString*)units input:(INPUT_MODE)input is_ac:(bool)is_ac {
    self = [super init];
    self.name = name;
    self.units = units;
    self.input = input;
    self.is_ac = is_ac;
    return self;
}
-(void) addRange:(NSString*)name converter:(Lsb2NativeConverter)conv max:(float)max gain:(PGA_GAIN)gain gpio:(GPIO_SETTING)gpio isrc:(ISRC_SETTING)isrc {
    myRangeDescriptor * ret = [[myRangeDescriptor alloc]init];
    ret.name=name;
    ret.max = max;
    ret.chset = 0;
    switch(self.input) {
        case NATIVE:
            ret.chset = 0x00;
            break;
        case TEMP:
            ret.chset = 0x04;
            break;
        case AUX_V:
        case RESISTANCE:
        case DIODE:
            ret.chset = 0x09;
            break;
        default:
            NSLog(@"Something's fucky");
            break;
    }
    switch(gain) {
        case PGA_GAIN_1:
            ret.chset |= 0x10;
            break;
        case PGA_GAIN_4:
            ret.chset |= 0x40;
            break;
        case PGA_GAIN_12:
            ret.chset |= 0x60;
            break;
        default:
            NSLog(@"You are a terrible person");
            break;
    }
    ret.gpio = gpio;
    ret.isrc = isrc;
    ret.converter = conv;
    [self.ranges add:ret];
}
@end

@interface MathInputDescriptor:InputDescriptor
@property bool (^meterSettingsAreValid)();
@property void (^onChosen)();
@property MeterReading* (^calculate)();
@end
@implementation MathInputDescriptor
@end

@implementation LegacyMooshimeterDevice

-(myInputDescriptor *)getSelectedDescriptor:(Channel)c {
    return [self->input_descriptors[c] getChosen];
}
-(myRangeDescriptor *)getSelectedRange:(Channel)c {
    InputDescriptor *i = [self getSelectedDescriptor:c];
    return [i.ranges getChosen];
}

-(float) getMaxRangeForChannel:(Channel)c {
    InputDescriptor *i = [self getSelectedDescriptor:c];
    int n_choices = [i.ranges getNChoices];
    RangeDescriptor *rval = [i.ranges get:n_choices-1];
    return rval.max;
}

-(MeterReading*)wrapMeterReading:(float)val c:(Channel)c {
    myInputDescriptor *id = [self getSelectedDescriptor:c];
    float enob = [self getENOB:c];
    float max = [self getMaxRangeForChannel:c];

    MeterReading* rval = [[MeterReading alloc]
            initWithValue:val
             n_digits_arg:(int)log10(pow(2.0, enob))
                  max_arg:max
                units_arg:id.units];
    return rval;
}

+(float)pgaGain:(PGA_GAIN)in {
    switch(in) {
        case PGA_GAIN_1:
            return 1;
        case PGA_GAIN_4:
            return 4;
        case PGA_GAIN_12:
            return 12;
        default:
            NSLog(@"You have fucked up now");
            return 0;
    }
}

-(float)lsb2PGAVoltage:(int)lsb {
    float Vref;
    switch(self->meter_info.pcb_version){
        case 7:
            Vref=2.5;
            break;
        case 8:
            Vref=2.42;
            break;
        default:
            NSLog(@"UNSUPPORTED:Unknown board type");
            return 0;
    }
    return ((float)lsb/(float)(1<<23))*Vref;
}

// Callback triggered by sample received
void (^sample_handler)(NSData*,NSError*);

-(LegacyMooshimeterDevice*) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    // Check for issues with struct packing.
    BUILD_BUG_ON(sizeof(trigger_settings_t) != 6);
    BUILD_BUG_ON(sizeof(MeterSettings_t)    != 13);
    BUILD_BUG_ON(sizeof(meter_state_t)      != 1);
    BUILD_BUG_ON(sizeof(MeterLogSettings_t) != 16);
    self = [super init];

    self.periph = periph;
    self.chars = nil;

    self->input_descriptors[0] = [[Chooser alloc]init];
    self->input_descriptors[1] = [[Chooser alloc]init];

    sample_handler = ^(NSData *data, NSError *error) {
        [data getBytes:&self->meter_sample length:data.length];
        uint32 utc_time = [[NSDate date] timeIntervalSince1970];
        [self.delegate onSampleReceived:utc_time c:CH1  val:[self getValue:CH1]];
        [self.delegate onSampleReceived:utc_time c:CH2  val:[self getValue:CH2]];
        [self.delegate onSampleReceived:utc_time c:MATH val:[self getValue:MATH]];
    };

    return self;
}


long to_int32(int24_test arg) {
    long int retval;
    memcpy(&retval, &arg, 3);
    ((char*)&retval)[3] = retval & 0x00800000 ? 0xFF:0x00;
    return retval;
}

int24_test to_int24_test(long arg) {
    int24_test retval;
    memcpy(&retval, &arg, 3);
    return retval;
}

/*
 For convenience, builds a dictionary of the LGCharacteristics based on the relevant
 2 bytes of their UUID
 @param characteristics An array of LGCharacteristics
 @return void
 */

-(void)populateLGDict:(NSArray*)characteristics {
    for (LGCharacteristic* c in characteristics) {
        NSLog(@"    Char: %@", c.UUIDString);
        uint16 lookup;
        [c.cbCharacteristic.UUID.data getBytes:&lookup range:NSMakeRange(2, 2)];
        lookup = NSSwapShort(lookup);
        NSNumber* key = [NSNumber numberWithInt:lookup];
        [self.chars setObject:c forKey:key];
    }
}

/*
 Connects to the Mooshimeter and syncs the major data structures.
 Also updates the meter UTC time.
 */

-(void)connect {
    self.chars = [[NSMutableDictionary alloc] init];
    
    [self.periph connectWithTimeout:5 completion:^(NSError *error) {
        NSLog(@"Discovering services");
        [self.periph discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
            for (LGService *service in services) {
                if([service.UUIDString isEqualToString:[BLEUtility expandToMooshimUUIDString:METER_SERVICE_UUID]]) {
                    NSLog(@"METER SERVICE FOUND. Discovering characteristics.");
                    self->oad_mode = NO;
                    [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                        __unsafe_unretained typeof(self) weakSelf = self;
                        [weakSelf populateLGDict:characteristics];
                        [weakSelf reqMeterInfo:^(NSData *data, NSError *error) {
                            [weakSelf reqMeterSettings:^(NSData *data, NSError *error) {
                                [weakSelf reqMeterLogSettings:^(NSData *data, NSError *error) {
                                    [weakSelf reqMeterBatteryLevel:^(NSData *data, NSError *error) {
                                        uint32 utc_time = [[NSDate date] timeIntervalSince1970];
                                        [weakSelf setMeterTime:utc_time cb:^(NSError *error) {
                                            [weakSelf.periph registerDisconnectHandler:^(NSError *error) {
                                                [weakSelf accidentalDisconnect:error];
                                            }];
                                            [weakSelf.delegate onInit];
                                        }];
                                    }];
                                }];
                            }];
                        }];
                    }];
                } else if([service.UUIDString isEqualToString:[BLEUtility expandToMooshimUUIDString:OAD_SERVICE_UUID]]) {
                    NSLog(@"OAD SERVICE FOUND");
                    self->oad_mode = YES;
                    [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                        [self populateLGDict:characteristics];
                        [self.delegate onInit];
                    }];
                } else {
                    NSLog(@"Service I don't care about found.");
                }
            }
        }];
    }];
}

-(void)disconnect:(LGPeripheralConnectionCallback)aCallback {
    [self.periph disconnectWithCompletion:aCallback];
}

-(void)accidentalDisconnect:(NSError*)error {
    DLog(@"Accidental disconnect!");
    [self.delegate onDisconnect];
}

-(LGCharacteristic*)getLGChar:(uint16)UUID {
    return self.chars[[NSNumber numberWithInt:UUID]];
}

-(void)reqMeterStruct:(uint16)uuid target:(void*)target cb:(LGCharacteristicReadCallback)cb {
    LGCharacteristic* c = [self getLGChar:uuid];
    [c readValueWithBlock:^(NSData *data, NSError *error) {
        [data getBytes:target length:data.length];
        cb(data,error);
    }];
}

-(void)reqMeterInfo:(LGCharacteristicReadCallback)cb {
    [self reqMeterStruct:METER_INFO target:&self->meter_info cb:cb];
}

-(void)reqMeterSettings:(LGCharacteristicReadCallback)cb {
    [self reqMeterStruct:METER_SETTINGS target:&self->meter_settings cb:cb];
}

-(void)reqMeterLogSettings:(LGCharacteristicReadCallback)cb {
    [self reqMeterStruct:METER_LOG_SETTINGS target:&self->meter_log_settings cb:cb];
}

-(void)reqMeterSample:(LGCharacteristicReadCallback)cb {
    [self reqMeterStruct:METER_SAMPLE target:&self->meter_sample cb:cb];
}

-(void)reqMeterBatteryLevel:(LGCharacteristicReadCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_BAT];
    [c readValueWithBlock:^(NSData *data, NSError *error) {
        uint16 lsb;
        [data getBytes:&lsb length:data.length];
        // 12 bit reading, 1.24V reference, reading VDD/3
        self->bat_voltage = 3*1.24*(((double)lsb)/(1<<12));
        cb(data,error);
    }];
}

-(void)setMeterTime:(uint32)utc_time cb:(LGCharacteristicWriteCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_UTC_TIME];
    NSData *bytes = [NSData dataWithBytes:&utc_time length:4];
    [c writeValue:bytes completion:cb];
}

-(void)sendMeterName:(NSString*)name cb:(LGCharacteristicWriteCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_NAME];
    NSData *bytes = [name dataUsingEncoding:NSUTF8StringEncoding];
    [c writeValue:bytes completion:cb];
}

-(void)sendMeterSettings:(LGCharacteristicWriteCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_SETTINGS];
    NSData* v = [NSData dataWithBytes:&self->meter_settings length:sizeof(self->meter_settings)];
    [c writeValue:v completion:cb];
}

-(void)sendMeterLogSettings:(LGCharacteristicWriteCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_LOG_SETTINGS];
    NSData* v = [NSData dataWithBytes:&self->meter_log_settings length:sizeof(self->meter_log_settings)];
    [c writeValue:v completion:cb];
}

// Returns the maximum value of the next measurement range down superimposed on the current range

-(RangeDescriptor*)getLowerRange:(int)channel {
    uint8 const pga_setting    = [self getChannelSetting:channel]&METER_CH_SETTINGS_PGA_MASK;
    uint8* const adc_setting = &self->meter_settings.rw.adc_settings;
    uint8* const ch3_mode    = &self->disp_settings.ch3_mode;
    uint8* const measure_setting = &self->meter_settings.rw.measure_settings;
    int8 tmp;

    InputDescriptor *i = [self getSelectedDescriptor:channel];
    int to_choose = i.ranges.chosen_i;
    if(to_choose>0) {
        to_choose--;
    }
    return [i.ranges get:to_choose]
}

-(bool)applyRateAndDepthChange {
    // Autorange sample rate and buffer depth.
    // If anything is doing AC, we need a deep buffer and fast sample
    bool ac_used = NO;
    ac_used |= ((myInputDescriptor *)[self getSelectedDescriptor:CH1]).is_ac;
    ac_used |= ((myInputDescriptor *)[self getSelectedDescriptor:CH2]).is_ac;
    MeterSettings_t tmp = self->meter_settings;
    MeterSettings_t* ms = &self->meter_settings;
    if(self.rate_auto) {
        ms->rw.adc_settings &=~ADC_SETTINGS_SAMPLERATE_MASK;
        if(ac_used) ms->rw.adc_settings |= 5; // 4kHz
        else        ms->rw.adc_settings |= 0; // 125Hz
    }
    if(self.depth_auto) {
        ms->rw.calc_settings &=~METER_CALC_SETTINGS_DEPTH_LOG2;
        if(ac_used) ms->rw.calc_settings |= 8; // 256 samples
        else        ms->rw.calc_settings |= 5; // 32 samples
    }
    // TODO: Should we send the structure here?
    return 0 != memcmp(&tmp,ms,sizeof(MeterSettings_t));
}

-(bool)applyAutorange:(Channel) c {
    MeterSettings_t* const ms = &self->meter_settings;

    myInputDescriptor* active_id = [self getSelectedDescriptor:c];

    float outer_limit = ((RangeDescriptor *)[active_id.ranges getChosen]).max;
    float inner_limit = (float)0.7*[self getLowerRange:c].max;
    // Note that the ranges are asymmetrical - we have 1.8V of headroom above and 1.2V below
    float val = ABS([self getValue:c].value);

    if(val < inner_limit) {
        [self bumpRange:c expand:NO];
    } else if(val > outer_limit) {
        [self bumpRange:c expand:YES];
    }
}

-(void)handleBufStreamUpdate:(NSData*) data channel:(int)channel {
    static BOOL ch1_last_received = NO;
    static int buf_i = 0;
    uint16 buf_len_bytes = [self getBufLen]*sizeof(int24_test);
    uint8* target;
    NSLog(@"Buf: %d: %d", channel, buf_i);
    if(channel == 0) {
        if(!ch1_last_received){buf_i = 0;}
        ch1_last_received = YES;
        target = (uint8*)self->sample_buf.CH1_buf;
        target+= buf_i;
        [data getBytes:target length:data.length];
        buf_i += data.length;
    } else if(channel == 1) {
        if(ch1_last_received){buf_i = 0;}
        ch1_last_received = NO;
        target = (uint8*)self->sample_buf.CH2_buf;
        target+= buf_i;
        [data getBytes:target length:data.length];
        buf_i += data.length;
        if(buf_i >= buf_len_bytes) {
            NSLog(@"Complete buffer received!");
            if(self->buffer_cb) self->buffer_cb();
        }
    } else {
        NSLog(@"WTF");
    }
}

-(void)setMeterState:(int)new_state cb:(LGCharacteristicWriteCallback)cb {
    self->meter_settings.rw.target_meter_state = new_state;
    [self sendMeterSettings:cb];
}

-(int24_test*)getBuf:(int) channel {
    switch(channel) {
        case 0:
            return self->sample_buf.CH1_buf;
        case 1:
            return self->sample_buf.CH2_buf;
        default:
            DLog(@"SHould not be here");
            return self->sample_buf.CH1_buf;
    }
}

-(uint8)getChannelSetting:(int)ch {
    switch(ch) {
        case 0:
            return self->meter_settings.rw.ch1set;
        case 1:
            return self->meter_settings.rw.ch2set;
        default:
            DLog(@"Invalid channel");
            return 0;
    }
}

/*
 Return a rough appoximation of the ENOB of the channel
 For the purposes of figuring out how many digits to display
 Based on ADS1292 datasheet and some special sauce.
 And empirical measurement of CH1 (which is super noisy due to chopper)
 */

-(double)getENOB:(int)channel {
    const double base_enob_table[] = {
        20.10,
        19.58,
        19.11,
        18.49,
        17.36,
        14.91,
        12.53};
    const int pga_gain_table[] = {6,1,2,3,4,8,12};
    const int samplerate_setting =self->meter_settings.rw.adc_settings & ADC_SETTINGS_SAMPLERATE_MASK;
    const int buffer_depth_log2 = self->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2;
    double enob = base_enob_table[ samplerate_setting ];
    int pga_setting = channel==1? self->meter_settings.rw.ch1set:self->meter_settings.rw.ch2set;
    pga_setting &= METER_CH_SETTINGS_PGA_MASK;
    pga_setting >>= 4;
    int pga_gain = pga_gain_table[pga_setting];
    // At lower sample frequencies, pga gain affects noise
    // At higher frequencies it has no effect
    double pga_degradation = (1.5/12) * pga_gain * ((6-samplerate_setting)/6.0);
    enob -= pga_degradation;
    // Oversampling adds 1 ENOB per factor of 4
    enob += ((double)buffer_depth_log2)/2.0;
    //
    if(meter_info.pcb_version==7 && channel == 0 && (self->meter_settings.rw.ch1set & METER_CH_SETTINGS_INPUT_MASK) == 0 ) {
        // This is compensation for a bug in RevH, where current sense chopper noise dominates
        enob -= 2;
    }
    return enob;
}

/*
 Based on the ENOB and the measurement range, calculate the number of noise-free digits that can be displayed
 @param channel Input channel index (0 or 1)
 @return a SignificantDigits structure, with member max_dig indicating the number of digits left of the point and n_digits indicating the total number of digits
 */

-(SignificantDigits*)getSigDigits:(int)channel {
    SignificantDigits retval;
    double enob = [self getENOB:channel];
    double max = [self lsbToNativeUnits:(1<<22) ch:channel];
    double max_dig  = log10(max);
    double n_digits = log10(pow(2.0,enob));
    retval.high = max_dig+1;
    retval.n_digits = n_digits;
    return retval;
}

/*
 Convert ADC counts to the voltage at the AFE input
 @param reading_lsb reading from the ADC
 @param channel input channel (0 or 1)
 @return Voltage at the AFE input (before the PGA)
 */

-(double)lsbToADCInVoltage:(int)reading_lsb channel:(int)channel {
    // This returns the input voltage to the ADC,
    const double Vref = meter_info.pcb_version==7 ? 2.5:2.42;
    const double pga_lookup[] = {6,1,2,3,4,8,12};
    int pga_setting=0;
    switch(channel) {
        case 0:
            pga_setting = self->meter_settings.rw.ch1set >> 4;
            break;
        case 1:
            pga_setting = self->meter_settings.rw.ch2set >> 4;
            break;
        default:
            DLog(@"Should not be here");
            break;
    }
    double pga_gain = pga_lookup[pga_setting];
    return ((double)reading_lsb/(double)(1<<23))*Vref/pga_gain;
}

/*
 Convert voltage at the AFE input to voltage at the high voltage terminal
 @param adc_voltage voltage at AFE (before PGA)
 @return voltage in volts
 */

-(double)adcVoltageToHV:(double)adc_voltage {
    switch( (self->meter_settings.rw.adc_settings & ADC_SETTINGS_GPIO_MASK) >> 4 ) {
        case 0x00:
            // 1.2V range
            return adc_voltage;
        case 0x01:
            // 60V range
            return ((10e6+160e3)/(160e3)) * adc_voltage;
        case 0x02:
            // 1000V range
            return ((10e6+11e3)/(11e3)) * adc_voltage;
        default:
            DLog(@"Invalid setting!");
            return 0.0;
    }
}


/*
 Convert voltage at the AFE input to ADC temperature
 @param adc_voltage voltage at AFE (before PGA)
 @return temperature in degrees C
 */

-(double)adcVoltageToTemp:(double)adc_voltage {
    adc_voltage -= 145.3e-3; // 145.3mV @ 25C
    adc_voltage /= 490e-6;   // 490uV / C
    return 25.0 + adc_voltage;
}

/*
 Convert the input in ADC counts to native units at the input terminal.
 @param lsb The value to be converted (in ADC counts)
 @param ch The channel index
 @return The value at the input terminal in native units (volts, amps, ohms, degrees C)
 */

-(float) lsbToNativeUnits:(int)lsb channel:(Channel)c {
    myRangeDescriptor * tmp = [self getSelectedRange:c];
    return tmp.converter(lsb);
}

/*
 The advertised build time is built in to the advertising data sent by a Mooshimeter.
 It is the UTC timestamp of the firmware image running on the meter.
 If the meter has no valid firmware image, the OAD image will broadcast 0 as the build time.
 */

-(uint32) getAdvertisedBuildTime {
    uint32 build_time = 0;
    NSData* tmp;
    tmp = [self.periph.advertisingData valueForKey:@"kCBAdvDataManufacturerData"];
    if( tmp != nil ) {
        [tmp getBytes:&build_time length:4];
    }
    return build_time;
}

#pragma mark MooshimeterControlProtocol_methods

////////////////////////////////
// Convenience functions
////////////////////////////////

-(bool)isInOADMode {
    return self->oad_mode;
}

//////////////////////////////////////
// Autoranging
//////////////////////////////////////

-(int)setRange:(Channel)c rangeDescriptor:(myRangeDescriptor *)rd {
    Chooser* chooser = [self getSelectedDescriptor:c];
    [chooser chooseObject:rd];

    meter_settings.rw.chset[c] = rd.chset;
    switch(rd.isrc) {
        case ISRC_IGNORE:
            break;
        case ISRC_OFF:
            self->meter_settings.rw.measure_settings=0;
            break;
        case ISRC_LOW:
            self->meter_settings.rw.measure_settings=METER_MEASURE_SETTINGS_ISRC_ON;
            break;
        case ISRC_MID:
            self->meter_settings.rw.measure_settings=METER_MEASURE_SETTINGS_ISRC_LVL;
            break;
        case ISRC_HIGH:
            self->meter_settings.rw.measure_settings=METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL;
            break;
        default:
            NSLog(@"Invalid ISRC setting");
            break;
    }
    switch(rd.gpio){
        case GPIO_IGNORE:
            break;
        case GPIO0:
            self->meter_settings.rw.adc_settings&=~ADC_SETTINGS_GPIO_MASK;
            break;
        case GPIO1:
            self->meter_settings.rw.adc_settings&=~ADC_SETTINGS_GPIO_MASK;
            self->meter_settings.rw.adc_settings |= 0x10;
            break;
        case GPIO2:
            self->meter_settings.rw.adc_settings&=~ADC_SETTINGS_GPIO_MASK;
            self->meter_settings.rw.adc_settings |= 0x20;
            break;
        case GPIO3:
            self->meter_settings.rw.adc_settings&=~ADC_SETTINGS_GPIO_MASK;
            self->meter_settings.rw.adc_settings |= 0x30;
            break;
        default:
            NSLog(@"Invalid GPIO setting");
    }
    [self.delegate onRangeChange:c new_range:rd];
    return 0;
}

-(bool)bumpRange:(Channel)channel expand:(bool)expand {
    InputDescriptor * inputDescriptor = [self getSelectedDescriptor:channel];
    Chooser* ranges = inputDescriptor.ranges;
    if(!expand && ranges.chosen_i>0) {
        [ranges chooseByIndex:ranges.chosen_i-1];
        [self setRange:channel rangeDescriptor:[ranges getChosen]];
        return YES;
    }
    if(expand && ranges.chosen_i< [ranges getNChoices]-1) {
        [ranges chooseByIndex:ranges.chosen_i+1];
        [self setRange:channel rangeDescriptor:[ranges getChosen]];
        return YES;
    }
    return NO;
}

+(Lsb2NativeConverter)makeSimpleConverter:(float)mult pga:(PGA_GAIN)pga {
    // "mult" should be the multiple to convert from voltage at the input to the ADC (after PGA)
    // to native units
    float pga_mult = 1/[LegacyMooshimeterDevice pgaGain:pga];
    __weak LegacyMooshimeterDevice * weakself = self;
    Lsb2NativeConverter rval = ^float(int lsb) {
        if(!weakself) {return 0;}
        return [weakself lsb2PGAVoltage:lsb]*pga_mult*mult;
    };
    return rval;
};

+(Lsb2NativeConverter)makeResistiveConverter:(ISRC_SETTING)isrc pga:(PGA_GAIN)pga {
    // "mult" should be the multiple to convert from voltage at the input to the ADC (after PGA)
    // to native units
    float pga_mult = 1/[LegacyMooshimeterDevice pgaGain:pga];
    float isrc_res;
    float ptc_res = (float)7.9;
    float avdd=(float)(3-1.21);
    switch(isrc) {
        case ISRC_LOW:
            isrc_res = (float)10310e3;
            break;
        case ISRC_MID:
            isrc_res = (float)310e3;
            break;
        case ISRC_HIGH:
            isrc_res = (float)10e3;
            break;
        default:
            NSLog(@"UNSUPPORTED:Unknown ISRC setting");
            isrc_res = 0;
    }
    __weak LegacyMooshimeterDevice * weakself = self;
    Lsb2NativeConverter rval = ^float(int lsb) {
        if(!weakself){return 0;}
        float adc_volts = [weakself lsb2PGAVoltage:lsb]*pga_mult;
        return ((adc_volts/(avdd-adc_volts))*isrc_res) - ptc_res;
    };
    return rval;
};

-(void)addSharedInputs:(Chooser*)chooser {

    myInputDescriptor *descriptor;
    descriptor = [[myInputDescriptor alloc] initWithName:@"AUX VOLTAGE DC" units:@"V" input:AUX_V is_ac:NO];
    [descriptor addRange:@"100mV" converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_12 ] max:0.1 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_OFF];
    [descriptor addRange:@"300mV" converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_4 ] max:0.3 gain:PGA_GAIN_4  gpio:GPIO_IGNORE isrc:ISRC_OFF];
    [descriptor addRange:@"1.2V"  converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_1 ] max:1.2 gain:PGA_GAIN_1  gpio:GPIO_IGNORE isrc:ISRC_OFF];
    [chooser add:descriptor];
    descriptor = [[myInputDescriptor alloc] initWithName:@"AUX VOLTAGE AC" units:@"V" input:AUX_V is_ac:YES];
    [descriptor addRange:@"100mV" converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_12 ] max:0.1 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_OFF];
    [descriptor addRange:@"300mV" converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_4 ] max:0.3 gain:PGA_GAIN_4  gpio:GPIO_IGNORE isrc:ISRC_OFF];
    [descriptor addRange:@"1.2V"  converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_1 ] max:1.2 gain:PGA_GAIN_1  gpio:GPIO_IGNORE isrc:ISRC_OFF];
    [chooser add:descriptor];
    descriptor = [[myInputDescriptor alloc] initWithName:@"RESISTANCE" units:@"Ω" input:RESISTANCE is_ac:NO];

    switch (meter_info.pcb_version) {
        case 7:
            [descriptor addRange:@"1kΩ"   converter:[LegacyMooshimeterDevice makeSimpleConverter:(1/100e-6) pga:PGA_GAIN_12] max:1e3 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_HIGH];
            [descriptor addRange:@"10kΩ"  converter:[LegacyMooshimeterDevice makeSimpleConverter:(1/100e-6) pga:PGA_GAIN_1 ] max:1e4 gain:PGA_GAIN_1  gpio:GPIO_IGNORE isrc:ISRC_HIGH];
            [descriptor addRange:@"100kΩ" converter:[LegacyMooshimeterDevice makeSimpleConverter:(1/100e-9) pga:PGA_GAIN_12] max:1e5 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_LOW];
            [descriptor addRange:@"1MΩ"   converter:[LegacyMooshimeterDevice makeSimpleConverter:(1/100e-9) pga:PGA_GAIN_12] max:1e6 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_LOW];
            [descriptor addRange:@"10MΩ"  converter:[LegacyMooshimeterDevice makeSimpleConverter:(1/100e-9) pga:PGA_GAIN_1 ] max:1e7 gain:PGA_GAIN_1  gpio:GPIO_IGNORE isrc:ISRC_LOW];
        case 8:
            [descriptor addRange:@"1kΩ"   converter:[LegacyMooshimeterDevice makeResistiveConverter:ISRC_HIGH pga:PGA_GAIN_12] max:1e3 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_HIGH];
            [descriptor addRange:@"10kΩ"  converter:[LegacyMooshimeterDevice makeResistiveConverter:ISRC_HIGH pga:PGA_GAIN_1 ] max:1e4 gain:PGA_GAIN_1  gpio:GPIO_IGNORE isrc:ISRC_HIGH];
            [descriptor addRange:@"100kΩ" converter:[LegacyMooshimeterDevice makeResistiveConverter:ISRC_LOW  pga:PGA_GAIN_12] max:1e5 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_LOW];
            [descriptor addRange:@"1MΩ"   converter:[LegacyMooshimeterDevice makeResistiveConverter:ISRC_LOW  pga:PGA_GAIN_12] max:1e6 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_LOW];
            [descriptor addRange:@"10MΩ"  converter:[LegacyMooshimeterDevice makeResistiveConverter:ISRC_LOW  pga:PGA_GAIN_1 ] max:1e7 gain:PGA_GAIN_1  gpio:GPIO_IGNORE isrc:ISRC_LOW];
            break;
        default:
            NSLog(@"Unrecognized PCB type");
            break;
    }
    descriptor = [[myInputDescriptor alloc] initWithName:@"DIODE DROP" units:@"V" input:DIODE is_ac:NO];
    [descriptor addRange:@"1.7V" converter:[LegacyMooshimeterDevice makeSimpleConverter:1 pga:PGA_GAIN_12 ] max:1.7 gain:PGA_GAIN_12 gpio:GPIO_IGNORE isrc:ISRC_HIGH];
    [chooser add:descriptor];
    descriptor = [[myInputDescriptor alloc] initWithName:@"INTERNAL TEMP" units:@"K" input:TEMP is_ac:NO];
    Lsb2NativeConverter temp_converter = ^float(int lsb) {
        float volts = [self lsb2PGAVoltage:lsb];
        // PGA gain is 1, so PGA voltage=ADC voltage
        return (float)(volts/490e-6);
    };
    [descriptor addRange:@"350K" converter:temp_converter max:350 gain:PGA_GAIN_1 gpio:GPIO_IGNORE isrc:ISRC_IGNORE];
    [chooser add:descriptor];
}

-(int)initialize {
    // This should be called after connect and discovery are done

    float i_gain;
    switch(meter_info.pcb_version){
        case 7:
            i_gain = (float)(1/80e-3);
            break;
        case 8:
            i_gain = (float)(1/10e-3);
            break;
        default:
            NSLog(@"UNSUPPORTED:Unknown board type");
            i_gain = 0;
            break;
    }

    Chooser* c = input_descriptors[0];

    Lsb2NativeConverter (^simple_converter)(float mult) = ^Lsb2NativeConverter(float mult) {
        return [LegacyMooshimeterDevice makeSimpleConverter:mult pga:PGA_GAIN_1];
    };

    // Add channel 1 ranges and inputs
    myInputDescriptor *descriptor;

    descriptor = [[myInputDescriptor alloc] initWithName:@"CURRENT DC" units:@"A" input:NATIVE is_ac:NO];
    [descriptor addRange:@"10" converter:simple_converter(i_gain) max:10 gain:PGA_GAIN_1 gpio:GPIO_IGNORE isrc:ISRC_IGNORE];
    [c add:descriptor];
    descriptor = [[myInputDescriptor alloc] initWithName:@"CURRENT AC" units:@"A" input:NATIVE is_ac:YES];
    [descriptor addRange:@"10" converter:simple_converter(i_gain) max:10 gain:PGA_GAIN_1 gpio:GPIO_IGNORE isrc:ISRC_IGNORE];
    [c add:descriptor];
    [self addSharedInputs:c];

    // Add channel 2 ranges and inputs
    c = input_descriptors[1];
    descriptor = [[myInputDescriptor alloc] initWithName:@"VOLTAGE DC" units:@"V" input:NATIVE is_ac:NO];
    [descriptor addRange:@"60V"  converter:simple_converter(((10e6 + 160e3) / 160e3)) max:60  gain:PGA_GAIN_1 gpio:GPIO1 isrc:ISRC_IGNORE];
    [descriptor addRange:@"600V" converter:simple_converter(((10e6 + 11e3) / 11e3)  ) max:600 gain:PGA_GAIN_1 gpio:GPIO2 isrc:ISRC_IGNORE];
    [c add:descriptor];
    descriptor = [[myInputDescriptor alloc] initWithName:@"VOLTAGE AC" units:@"V" input:NATIVE is_ac:YES];
    [descriptor addRange:@"60V"  converter:simple_converter(((10e6 + 160e3) / 160e3)) max:60  gain:PGA_GAIN_1 gpio:GPIO1 isrc:ISRC_IGNORE];
    [descriptor addRange:@"600V" converter:simple_converter(((10e6 + 11e3) / 11e3)  ) max:600 gain:PGA_GAIN_1 gpio:GPIO2 isrc:ISRC_IGNORE];
    [c add:descriptor];
    [self addSharedInputs:c];
}

// Return true if settings changed
-(bool)applyAutorange {
    bool rval = NO;
    rval|=[self applyAutorange:CH1];
    rval|=[self applyAutorange:CH2];
    rval|=[self applyRateAndDepthChange];
    if(rval) {
        [self sendMeterSettings:nil];
    }
    return rval;
}

//////////////////////////////////////
// Interacting with the Mooshimeter itself
//////////////////////////////////////

-(void)setName:(NSString*)name {
    [self sendMeterName:name cb:nil];
}
-(NSString*)getName {
    ]
}

-(void)pause {
    self->meter_settings.rw.target_meter_state = METER_PAUSED;
    [self sendMeterSettings:nil];
}
-(void)oneShot {
    self->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_ONESHOT;
    self->meter_settings.rw.target_meter_state = METER_RUNNING;
    [self sendMeterSettings:nil];
}

-(void)stream {
    self->meter_settings.rw.calc_settings &=~METER_CALC_SETTINGS_ONESHOT;
    self->meter_settings.rw.target_meter_state = METER_RUNNING;
    [self sendMeterSettings:nil];
    LGCharacteristic* c = [self getLGChar:METER_SAMPLE];
    [c setNotifyValue:YES completion:nil onUpdate:sample_handler];
}

-(void)enterShippingMode {
    self->meter_settings.rw.target_meter_state = METER_HIBERNATE;
    [self sendMeterSettings:nil];
}

-(int)getPCBVersion {
    return meter_info.pcb_version;
}

-(double)getUTCTime {
    [self getLGChar:METER_UTC_TIME];
    fewafewafewa
}
-(void)setTime:(double) utc_time {
    [self setMeterTime:(uint32)utc_time cb:nil];
}

-(MeterReading*) getOffset:(Channel)c {
    return [self wrapMeterReading:self->offsets[c] c:c];
}

-(void)setOffset:(Channel)c offset:(float)offset {
    self->offsets[c]=offset;
    return;
}

-(int)getSampleRateHz {
    int rval = 125;
    int mult = 1;
    mult <<= (meter_settings.rw.adc_settings & ADC_SETTINGS_SAMPLERATE_MASK);
    return rval*mult;
}
-(int)setSampleRateIndex:(int)i {
    meter_settings.rw.adc_settings &=(~ADC_SETTINGS_SAMPLERATE_MASK);
    meter_settings.rw.adc_settings |= i;
    [self sendMeterSettings:nil];
}
-(NSArray<NSString*>*) getSampleRateList {
    static const int l[] = {125,250,500,1000,2000,4000,8000};
    NSMutableArray<NSString*>* rval = [[NSArray alloc]init];
    for(int i = 0; i < sizeof(l)/sizeof(l[0]); i++) {
        NSString* element = [NSString stringWithFormat:@"%d", l[i]]
        [rval addObject:element];
    }
    return rval;
}

-(int)getBufferDepth {
    return (1<<(self->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2));
}

-(int)setBufferDepthIndex:(int)i {
    self->meter_settings.rw.calc_settings &=~METER_CALC_SETTINGS_DEPTH_LOG2;
    self->meter_settings.rw.calc_settings |= i;
}
-(NSArray<NSString*>*) getBufferDepthList {
    static const int l[] = {1,2,4,8,16,32,64,128,256};
    NSMutableArray<NSString*>* rval = [[NSArray alloc]init];
    for(int i = 0; i < sizeof(l)/sizeof(l[0]); i++) {
        NSString* element = [NSString stringWithFormat:@"%d", l[i]]
        [rval addObject:element];
    }
    return rval;
}

-(void)setBufferMode:(Channel)c on:(bool)on {
    /**
     * Downloads the complete sample buffer from the Mooshimeter.
     * This interaction spans many connection intervals, the exact length depends on the number of samples in the buffer
     * @param onReceived Called when the complete buffer has been downloaded
     */
    LGCharacteristic* s  = [self getLGChar:METER_SAMPLE];
    LGCharacteristic* c1 = [self getLGChar:METER_CH1BUF];
    LGCharacteristic* c2 = [self getLGChar:METER_CH2BUF];

    if(on) {
        // Set up for oneshot, turn off all math in firmware
        if (([self getAdvertisedBuildTime] < 1424473383)
                && (0 == (self->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_ONESHOT))) {
            // Avoid sending the same meter settings over and over - check and see if we're set up for oneshot
            // and if we are, don't send the meter settings again.  Due to a firmware bug in the wild (Feb 2 2015)
            // sending meter settings will cause the ADC to run for one buffer fill even if the state is METER_PAUSED
            meter_settings.rw.calc_settings &= ~(METER_CALC_SETTINGS_MS | METER_CALC_SETTINGS_MEAN);
            meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_ONESHOT;
        } else if (meter_settings.ro.present_meter_state != METER_PAUSED) {
            //meter_settings.target_meter_state = METER_PAUSED;
            //meter_settings.send();
        }

        [s setNotifyValue:NO completion:nil];
        [c1 setNotifyValue:on completion:^(NSError *error) {
            [c2 setNotifyValue:on completion:cb onUpdate:^(NSData *data, NSError *error) {
                [self handleBufStreamUpdate:data channel:1];
            }];
        } onUpdate:^(NSData *data, NSError *error) {
            [self handleBufStreamUpdate:data channel:0];
        }];
    } else {
        [s setNotifyValue:YES completion:nil onUpdate:<#(LGCharacteristicReadCallback)uCallback#>];
        [c1 setNotifyValue:NO completion:nil];
        [c2 setNotifyValue:NO completion:nil];
    }
}

-(bool)getLoggingOn {
    bool rval = meter_log_settings.ro.present_logging_state != LOGGING_OFF;
    rval &= meter_log_settings.rw.target_logging_state != LOGGING_OFF;
    return rval;
}
-(void)setLoggingOn:(bool)on {
    meter_log_settings.rw.target_logging_state = on?LOGGING_SAMPLING:LOGGING_OFF;
    [self sendMeterLogSettings:nil];
}
-(int)getLoggingStatus {
    return meter_log_settings.ro.logging_error;
}
-(NSString*)getLoggingStatusMessage {
    static const char* messages[] = {
        "LOGGING_OK",
        "LOGGING_NO_MEDIA",
        "LOGGING_MOUNT_FAIL",
        "LOGGING_INSUFFICIENT_SPACE",
        "LOGGING_WRITE_ERROR",
        "LOGGING_END_OF_FILE", };
    return [NSString stringWithUTF8String:messages[[self getLoggingStatus]]];
}
-(void)setLoggingInterval:(int)ms {
    meter_log_settings.rw.logging_period_ms=ms;
    [self sendMeterLogSettings:nil];
}
-(int)getLoggingIntervalMS {
    return meter_log_settings.rw.logging_period_ms;
}

-(MeterReading*) getValue:(Channel)c {
    switch(c) {
        case CH1:
        case CH2:
            if(((myInputDescriptor *)[self getSelectedDescriptor:c]).is_ac) {
                return [self wrapMeterReading:[self lsbToNativeUnits:(int)sqrt(meter_sample.ch_ms[c]) channel:c] c:c];
            } else {
                return [self wrapMeterReading:[self lsbToNativeUnits:to_int32(meter_sample.ch_reading_lsb[c]) channel:c]+[self getOffset:c].value c:c];
            }
            break;
        case MATH: {
            MathInputDescriptor *d = (MathInputDescriptor *) [input_descriptors[c] getChosen];
            if (d.meterSettingsAreValid()) {
                return d.calculate();
            } else {
                return [[MeterReading alloc]
                        initWithValue:0
                         n_digits_arg:1
                              max_arg:1
                            units_arg:@"INVALID"];
            }
        } break;
    }
    return [[MeterReading alloc]
            initWithValue:0
             n_digits_arg:1
                  max_arg:1
                units_arg:@"INVALID"];
}

-(NSString*) getRangeLabel:(Channel) c {
    return [self getSelectedRange:c].name;
}
-(int)         setRange:(Channel)c rd:(id)rd {
    InputDescriptor * inputDescriptor = [self getSelectedDescriptor:c];
    [inputDescriptor.ranges chooseObject:rd];
}
-(NSArray<NSString*>*) getRangeList:(Channel)c {
    InputDescriptor * inputDescriptor = [self getSelectedDescriptor:c];
    Chooser* r = inputDescriptor.ranges;
    NSMutableArray<NSString*>* rval = [NSMutableArray arrayWithCapacity:[r getNChoices] ];
    for(unsigned int i = 0; i < [r getNChoices]; i++) {
        RangeDescriptor * rd = [r get:i];
        rval[i] = rd.name;
    }
    return rval;
}

-(NSString*) getInputLabel:(Channel)c {
    InputDescriptor * inputDescriptor = [self getSelectedDescriptor:c];
    return inputDescriptor.name;
}

bool isSharedInput(INPUT_MODE i) {
    return  (i==RESISTANCE) ||
            (i==AUX_V) ||
            (i==DIODE);
};

-(int)setInput:(Channel)c descriptor:(InputDescriptor*)new_id {
    Chooser* id_chooser = self->input_descriptors[c];
    myInputDescriptor * cast = (myInputDescriptor *)new_id;
    switch(c) {
        case CH1:
        case CH2:
            if([id_chooser getChosen]==new_id) {
                // No action required
                return 0;
            }

            if(isSharedInput(cast.input)) {
                // Make sure we're not about to jump on to a channel that's in use
                Channel other = c==CH1?CH2:CH1;
                myInputDescriptor * other_id = [self getSelectedDescriptor:other];
                if(isSharedInput(other_id.input)) {
                    NSLog(@"Tried to select an input already in use!");
                    return -1;
                }
            }

            [id_chooser chooseObject:cast];
            [self.delegate onInputChange:c descriptor:new_id];
            [self setRange:c rangeDescriptor:[new_id.ranges get:0]];
            return 0;
        case MATH:
            [(MathInputDescriptor*)new_id onChosen];
            [id_chooser chooseObject:new_id];
            return 0;
    }
    return 0;
}
-(NSArray *) getInputList:(Channel)c {
    Chooser* r = self->input_descriptors[c];
    NSMutableArray<NSString*>* rval = [NSMutableArray arrayWithCapacity:[r getNChoices] ];
    for(unsigned int i = 0; i < [r getNChoices]; i++) {
        InputDescriptor * rd = [r get:i];
        rval[i] = rd.name;
    }
    return rval;
}

@end
