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
    [ranges add:ret];
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

-(float) getMaxRangeForChannel:(Channel)c {
    fewafewafewa
}

-(MeterReading*)wrapMeterReading:(float)val c:(Channel)c {
    myInputDescriptor id = [self getSelectedDescriptor:c];
    float enob = [self getENOB:c];
    self getR
    float max = getMaxRangeForChannel(c);
    MeterReading rval;

    rval = new MeterReading(val,
            (int)Math.log10(Math.pow(2.0, enob)),
            max,
            id.units);

    MeterReading* rval = [[MeterReading alloc]
            initWithValue:val
             n_digits_arg:<#(int)n_digits_arg#>
                  max_arg:<#(float)max_arg#>
                units_arg:<#(NSString*)units_arg#>];
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

-(LegacyMooshimeterDevice*) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    // Check for issues with struct packing.
    BUILD_BUG_ON(sizeof(trigger_settings_t) != 6);
    BUILD_BUG_ON(sizeof(MeterSettings_t)    != 13);
    BUILD_BUG_ON(sizeof(meter_state_t)      != 1);
    BUILD_BUG_ON(sizeof(MeterLogSettings_t) != 16);
    self = [super init];

    self.p = periph;
    self.chars = nil;

    self->input_descriptors[0] = [[Chooser alloc]init];
    self->input_descriptors[1] = [[Chooser alloc]init];

    return self;
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
    
    [self.p connectWithTimeout:5 completion:^(NSError *error) {
        NSLog(@"Discovering services");
        [self.p discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
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
                                            [weakSelf.p registerDisconnectHandler:^(NSError *error) {
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
    [p disconnectWithCompletion:aCallback];
}

-(void)accidentalDisconnect:(NSError*)error {
    DLog(@"Accidental disconnect!");
    [self.delegate onDisconnect];
}

-(LGCharacteristic*)getLGChar:(uint16)UUID {
    return [self.chars objectForKey:[NSNumber numberWithInt:UUID]];
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

-(void)enableStreamMeterSample:(BOOL)on cb:(LGCharacteristicNotifyCallback)cb update:(BufferDownloadCompleteCB)update {
    self->sample_cb = update;
    LGCharacteristic* c = [self getLGChar:METER_SAMPLE];
    [c setNotifyValue:on completion:cb onUpdate:^(NSData *data, NSError *error) {
        [data getBytes:&self->meter_sample length:data.length];
        if(update) update();
    }];
}

+(uint8)pga_cycle:(uint8)chx_set inc:(BOOL)inc wrap:(BOOL)wrap {
    // These are the PGA settings we will entertain
    const uint8 ps[] = {0x60,0x40,0x10};
    int8 i;
    // Find the index of the present PGA setting
    for(i = 0; i < sizeof(ps); i++) {
        if(ps[i] == (chx_set & METER_CH_SETTINGS_PGA_MASK)) break;
    }
    
    if(i>=sizeof(ps)) {
        // If we didn't find it, default to setting 0
        i = 0;
    } else {
        // Increment or decrement the PGA setting
        if(inc){
            if(++i >= sizeof(ps)) {
                if(wrap){i=0;}
                else    {i--;}
            }
        }
        else {
            if(--i < 0) {
                if(wrap){i=sizeof(ps)-1;}
                else    {i++;}
            }
        }
    }
    // Mask the new setting back in
    chx_set &=~METER_CH_SETTINGS_PGA_MASK;
    chx_set |= ps[i];
    return chx_set;
}

-(int) getResLvl {
    int rval = meter_settings.rw.measure_settings & (METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL);
    return rval;
}
-(void)  setResLvl:(int) new_lvl {
    meter_settings.rw.measure_settings &=~(METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL);
    meter_settings.rw.measure_settings |= new_lvl;
}

-(void) bumpResLvl:(BOOL)expand wrap:(BOOL)wrap {
    int lvl = [self getResLvl];
    if(expand) {
        if(--lvl==0) {
            if(wrap) {lvl=3;}
            else     {lvl++;}
        }
    } else {
        if(++lvl==4) {
            if(wrap) {lvl=1;}
            else     {lvl--;}
        }
    }
    [self setResLvl:lvl];
}

// Returns the maximum value of the next measurement range down superimposed on the current range

-(int32)getLowerRange:(int)channel {
    uint8 const pga_setting    = [self getChannelSetting:channel]&METER_CH_SETTINGS_PGA_MASK;
    uint8* const adc_setting = &self->meter_settings.rw.adc_settings;
    uint8* const ch3_mode    = &self->disp_settings.ch3_mode;
    uint8* const measure_setting = &self->meter_settings.rw.measure_settings;
    int8 tmp;
    
    switch([self getChannelSetting:channel] & METER_CH_SETTINGS_INPUT_MASK) {
        case 0x00:
            // Electrode input
            switch(channel) {
                case 0:
                    // We are measuring current.  We can boost PGA, but that's all.
                    switch(pga_setting) {
                        case 0x60:
                            return 0;
                        case 0x40:
                            return 0.33*(1<<22);
                        case 0x10:
                            return 0.25*(1<<22);
                    }
                    break;
                case 1:
                    // Switch the ADC GPIO to activate dividers
                    tmp = (*adc_setting & ADC_SETTINGS_GPIO_MASK)>>4;
                    switch(tmp) {
                        case 1:
                            return 0;
                        case 2:
                            return 0.1*(1<<22);
                    }
                    break;
            }
            break;
        case 0x04:
            // Temp input
            return 0;
            break;
        case 0x09:
            switch(*ch3_mode) {
                case CH3_VOLTAGE:
                    switch(pga_setting) {
                        case 0x60:
                            return 0;
                        case 0x40:
                            return 0.33*(1<<22);
                        case 0x10:
                            return 0.25*(1<<22);
                    }
                    break;
                case CH3_RESISTANCE:
                case CH3_DIODE:
                    if(meter_info.pcb_version==7) {
                        switch(pga_setting) {
                            case 0x60:
                                if(0==(meter_settings.rw.measure_settings&METER_MEASURE_SETTINGS_ISRC_LVL))
                                {return (int)(0.012*(1<<22));}
                                else {return 0;}
                            case 0x40:
                                return (int)(0.33*(1<<22));
                            case 0x10:
                                return (int)(0.25*(1<<22));
                        }
                    } else {
                        // Assuming RevI
                        int lvl = [self getResLvl];
                        switch(lvl) {
                            case 0:
                                switch(pga_setting) {
                                    case 0x60:
                                        return 0;
                                    case 0x40:
                                        return (int) (0.33 * (1 << 22));
                                    case 0x10:
                                        return (int) (0.25 * (1 << 22));
                                }
                            case 1:
                                switch(pga_setting) {
                                    case 0x60:
                                    case 0x40:
                                        return (int) (0.33 * (1 << 22));
                                    case 0x10:
                                        return (int) (0.25 * (1 << 22));
                                }
                            case 2:
                                switch(pga_setting) {
                                    case 0x60:
                                    case 0x40:
                                        return (int) (0.33 * (1 << 22));
                                    case 0x10:
                                        return (int) (0.25 * (1 << 22));
                                }
                            case 3:
                                switch(pga_setting) {
                                    case 0x60:
                                        return 0;
                                    case 0x40:
                                        return (int) (0.33 * (1 << 22));
                                    case 0x10:
                                        return (int) (0.25 * (1 << 22));
                                }
                        }
                    }
                    break;
            }
            break;
    }
    return 0;
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

    const int32 upper_limit_lsb =  0.85*(1<<22);
    const int32 lower_limit_lsb = -0.85*(1<<22);

    int32 inner_limit_lsb = 0.7*[self getLowerRange:i];
    // Note that the ranges are asymmetrical - we have 1.8V of headroom above and 1.2V below
    int32 mean_lsb;
    double rms_lsb;
    mean_lsb = to_int32(self->meter_sample.ch_reading_lsb[c]);
    rms_lsb  = sqrt(self->meter_sample.ch_ms[c]);

    if(   mean_lsb > upper_limit_lsb
       || mean_lsb < lower_limit_lsb
       || rms_lsb*sqrt(2.) > ABS(lower_limit_lsb) ) {
        [self bumpRange:c expand:YES];
    } else if(   ABS(mean_lsb)    < inner_limit_lsb
              && rms_lsb*sqrt(2.) < inner_limit_lsb ) {
        [self bumpRange:c expand:NO];
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

-(void)enableStreamMeterBuf:(BOOL)on cb:(LGCharacteristicNotifyCallback)cb complete_buffer_cb:(BufferDownloadCompleteCB)complete_buffer_cb {
    self->buffer_cb = complete_buffer_cb;
    LGCharacteristic* c1 = [self getLGChar:METER_CH1BUF];
    LGCharacteristic* c2 = [self getLGChar:METER_CH2BUF];
    [c1 setNotifyValue:on completion:^(NSError *error) {
        [c2 setNotifyValue:on completion:cb onUpdate:^(NSData *data, NSError *error) {
            [self handleBufStreamUpdate:data channel:1];
        }];
    } onUpdate:^(NSData *data, NSError *error) {
        [self handleBufStreamUpdate:data channel:0];
    }];
}

-(void)setMeterState:(int)new_state cb:(LGCharacteristicWriteCallback)cb {
    self->meter_settings.rw.target_meter_state = new_state;
    [self sendMeterSettings:cb];
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

-(void)setChannelSetting:(int)ch set:(uint8)set {
    switch(ch) {
        case 0:
            self->meter_settings.rw.ch1set = set;
            break;
        case 1:
            self->meter_settings.rw.ch2set = set;
            break;
        default:
            DLog(@"Invalid channel");
            break;
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

-(SignificantDigits)getSigDigits:(int)channel {
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
 Convert voltage at the AFE input to current at the A terminal
 @param adc_voltage voltage at AFE (before PGA)
 @return Current in amps
 */

-(double)adcVoltageToCurrent:(double)adc_voltage {
    double rs;
    double amp_gain;
    if(meter_info.pcb_version==7){
        rs = 1e-3;
        amp_gain = 80.0;
    } else if(meter_info.pcb_version==8) {
        rs = 10e-3;
        amp_gain = 1.0;
    } else {
        // We want to raise an error
        rs=0;
        amp_gain=0;
    }
    return adc_voltage/(amp_gain*rs);
}

/*
 Examines the meter settings to determine the current source resistance on the RevI Mooshimeter
 Should never be called when talking to a RevH Mooshimeter
 @param none
 @return Source resistance of the current source on the RevI Mooshimeter
 */

-(double) getIsrcRes {
    int tmp = meter_settings.rw.measure_settings & (METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL);
    if(tmp == 0) {
        raise(1);
    } else if(tmp == METER_MEASURE_SETTINGS_ISRC_ON) {
        return 10e6+10e3+7.9;
    } else if(tmp == METER_MEASURE_SETTINGS_ISRC_LVL) {
        return 300e3+10e3+7.9;
    } else if(tmp == (METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL)) {
        return 10e3+7.9;
    } else {
        raise(1);
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

-(double)lsbToNativeUnits:(int)lsb ch:(int)ch {
    double adc_volts = 0;
    const double ptc_resistance = 7.9;
    double ohms = 0;
    uint8 channel_setting = [self getChannelSetting:ch] & METER_CH_SETTINGS_INPUT_MASK;
    if(self->disp_settings.raw_hex[ch]) {
        return lsb;
    }
    switch(channel_setting) {
        case 0x00:
            // Regular electrode input
            switch(ch) {
                case 0:
                    if(meter_info.pcb_version==7){
                        // CH1 offset is treated as an extrinsic offset because it's dominated by drift in the isns amp
                        adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                        adc_volts -= ch1_offset;
                        return [self adcVoltageToCurrent:adc_volts];
                    } else {
                        lsb -= ch1_offset;
                        adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                        return [self adcVoltageToCurrent:adc_volts];
                    }
                case 1:
                    lsb -= ch2_offset;
                    adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                    return [self adcVoltageToHV:adc_volts];
                default:
                    DLog(@"Invalid channel");
                    return 0;
            }
        case 0x04:
            adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
            return [self adcVoltageToTemp:adc_volts];
        case 0x09:
            // Channel 3 is complicated.  When measuring aux voltage, offset is dominated by intrinsic offsets in the ADC
            // When measuring resistance, offset is a resistance and must be treated as such
            if( 0 != (meter_settings.rw.measure_settings & (METER_MEASURE_SETTINGS_ISRC_ON|METER_MEASURE_SETTINGS_ISRC_LVL) ) ) {
                if(meter_info.pcb_version == 7) {
                    const double isrc_current = [self getIsrcCurrent];
                    adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                    adc_volts -= ptc_resistance*isrc_current;
                    adc_volts -= ch3_offset*isrc_current;
                    ohms = adc_volts/isrc_current;
                } else {
                    const double isrc_res = [self getIsrcRes];
                    const double avdd=3-1.21;
                    
                    adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                    ohms = ((adc_volts/(avdd-adc_volts))*isrc_res)-ptc_resistance;
                }
            } else {
                // Current source is off, offset is intrinsic
                lsb -= ch3_offset;
                adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                ohms=0;
            }
            if(disp_settings.ch3_mode == CH3_RESISTANCE) {
                return ohms;
            } else {
                return adc_volts;
            }
        default:
            DLog(@"Unrecognized channel setting");
            return adc_volts;
    }
}

/*
 Return a verbose description of the channel and measurement settings
 @param channel The channel index
 @return String describing what the channel is measuring
 */

-(NSString*)getDescriptor:(int)channel {
    uint8 channel_setting = [self getChannelSetting:channel] & METER_CH_SETTINGS_INPUT_MASK;
    switch( channel_setting ) {
        case 0x00:
            switch (channel) {
                case 0:
                    if(self->disp_settings.ac_display[channel]){
                        return @"Current AC";
                    } else {
                        return @"Current DC";
                    }
                case 1:
                    if(self->disp_settings.ac_display[channel]){
                        return @"Voltage AC";
                    } else {
                        return @"Voltage DC";
                    }
                default:
                    return @"Invalid";
            }
        case 0x04:
            // Temperature sensor
            return @"Temperature";
            break;
        case 0x09:
            // Channel 3 in
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    if(self->disp_settings.ac_display[channel]){
                        return @"Aux Voltage AC";
                    } else {
                        return @"Aux Voltage DC";
                    }
                case CH3_RESISTANCE:
                    return @"Resistance";
                case CH3_DIODE:
                    return @"Diode Test";
            }
            break;
        default:
            NSLog(@"Unrecognized setting");
            return @"";
    }
}

/*
 Returns the units label for the given channel
 @param channel The input channel index
 @return A string with the units (A, V, C, etc.)
 */

-(NSString*)getUnits:(int)channel {
    uint8 channel_setting = [self getChannelSetting:channel] & METER_CH_SETTINGS_INPUT_MASK;
    if(self->disp_settings.raw_hex[channel]) {
        return @"RAW";
    }
    switch( channel_setting ) {
        case 0x00:
            switch (channel) {
                case 0:
                    return @"A";
                case 1:
                    return @"V";
                default:
                    DLog(@"Invalid channel");
                    return @"?";
            }
        case 0x04:
            return @"C";
        case 0x09:
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    return @"V";
                case CH3_RESISTANCE:
                    return @"Ω";
                case CH3_DIODE:
                    return @"V";
            }
        default:
            NSLog(@"Unrecognized CH1SET setting");
            return @"";
    }
}

/*
 Returns a string describing the input terminal.  Can be V, A, Omega or Internal
 */

-(NSString*)getInputLabel:(int)channel {
    uint8 channel_setting = [self getChannelSetting:channel] & METER_CH_SETTINGS_INPUT_MASK;
    switch( channel_setting ) {
        case 0x00:
            switch (channel) {
                case 0:
                    return @"A";
                case 1:
                    return @"V";
                default:
                    return @"?";
            }
        case 0x04:
            return @"INT";
        case 0x09:
            return @"Ω";
        default:
            NSLog(@"Unrecognized setting");
            return @"";
    }
}

/*
 The advertised build time is built in to the advertising data sent by a Mooshimeter.
 It is the UTC timestamp of the firmware image running on the meter.
 If the meter has no valid firmware image, the OAD image will broadcast 0 as the build time.
 */

-(uint32) getAdvertisedBuildTime {
    uint32 build_time = 0;
    NSData* tmp;
    tmp = [self->p.advertisingData valueForKey:@"kCBAdvDataManufacturerData"];
    if( tmp != nil ) {
        [tmp getBytes:&build_time length:4];
    }
    return build_time;
}

/*
 Examines meter settings and returns the current coming out of the ISRC in A
 @returns current in A
 */

-(double)getIsrcCurrent {
    if( 0 == (meter_settings.rw.measure_settings & METER_MEASURE_SETTINGS_ISRC_ON) ) {
        return 0;
    }
    if( 0 != (meter_settings.rw.measure_settings & METER_MEASURE_SETTINGS_ISRC_LVL) ) {
        return 100e-6;
    } else {
        return 100e-9;
    }
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

-(bool)bumpRange:(Channel)channel expand:(bool)expand {
    uint8 channel_setting    = [self getChannelSetting:channel];
    uint8* const adc_setting = &self->meter_settings.rw.adc_settings;
    uint8* const ch3_mode    = &self->disp_settings.ch3_mode;
    int8 tmp;

    switch(channel_setting & METER_CH_SETTINGS_INPUT_MASK) {
        case 0x00:
            // Electrode input
            switch(channel) {
                case CH1:
                    // We are measuring current.  We can boost PGA, but that's all.
                    channel_setting = [LegacyMooshimeterDevice pga_cycle:channel_setting inc:expand wrap:wrap];
                    break;
                case CH2:
                    // Switch the ADC GPIO to activate dividers
                    // NOTE: Don't bother with the 1.2V range for now.  Having a floating autoranged input leads to glitchy behavior.
                    tmp = (*adc_setting & ADC_SETTINGS_GPIO_MASK)>>4;
                    if(raise) {
                        if(++tmp >= 3) {
                            tmp--;
                        }
                    } else {
                        if(--tmp < 1) {
                            tmp++;
                        }
                    }
                    tmp<<=4;
                    *adc_setting &= ~ADC_SETTINGS_GPIO_MASK;
                    *adc_setting |= tmp;
                    channel_setting &=~METER_CH_SETTINGS_PGA_MASK;
                    channel_setting |= 0x10;
                    break;
            }
            break;
        case 0x04:
            // Temp input
            break;
        case 0x09:
            switch(*ch3_mode) {
                case CH3_VOLTAGE:
                    channel_setting = [LegacyMooshimeterDevice pga_cycle:channel_setting inc:expand wrap:wrap];
                    break;
                case CH3_RESISTANCE:
                case CH3_DIODE:
                    if(meter_info.pcb_version==7) {
                        // This case is annoying.  We want PGA to always wrap if we are in the low range and going up OR in the high range and going down
                        if( 0 != ((expand?0:METER_MEASURE_SETTINGS_ISRC_LVL) ^ (meter_settings.rw.measure_settings & METER_MEASURE_SETTINGS_ISRC_LVL))) {
                            wrap = true;
                        }
                        channel_setting = [LegacyMooshimeterDevice pga_cycle:channel_setting inc:expand wrap:wrap];
                        tmp = channel_setting & METER_CH_SETTINGS_PGA_MASK;
                        tmp >>=4;
                        if(   ( expand && tmp == 6) || (!expand && tmp == 1) ) {
                            meter_settings.rw.measure_settings ^= METER_MEASURE_SETTINGS_ISRC_LVL;
                        }
                    } else {
                        int lvl = [self getResLvl];
                        BOOL inner_wrap = true;
                        if(lvl==1) {
                            // Res src is 10M
                            if(expand) {inner_wrap = wrap;}
                        } else if(lvl==3) {
                            // Res src is 10k
                            if(!expand) {inner_wrap = wrap;}
                        }
                        channel_setting = [LegacyMooshimeterDevice pga_cycle:channel_setting inc:expand wrap:inner_wrap];
                        tmp = channel_setting & METER_CH_SETTINGS_PGA_MASK;
                        tmp >>=4;
                        if( (expand && (tmp == 6)) || (!expand && (tmp == 1))) {
                            // The PGA wrapped, bump the macro range
                            [self bumpResLvl:expand wrap:wrap];
                        }
                    }
                    break;

            }
            break;
    }
    [g_meter setChannelSetting:channel set:channel_setting];
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
-(bool)applyAutorange;

//////////////////////////////////////
// Interacting with the Mooshimeter itself
//////////////////////////////////////

-(void)setName:(NSString*)name;
-(NSString*)getName;

-(void)pause;
-(void)oneShot;
-(void)stream;

-(void)enterShippingMode;

-(int)getPCBVersion {
    return meter_info.pcb_version;
}

-(double)getUTCTime {
    return
}
-(void)setTime:(double) utc_time {

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
    sendMeterSettings();
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
    fewafewa
}

-(bool)getLoggingOn {
    bool rval = meter_log_settings.ro.present_logging_state != LOGGING_OFF;
    rval &= meter_log_settings.rw.target_logging_state != LOGGING_OFF;
    return rval;
}
-(void)setLoggingOn:(bool)on {
    meter_log_settings.rw.target_logging_state = on?LOGGING_SAMPLING:LOGGING_OFF;
    sendLogSettings
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
        "LOGGING_END_OF_FILE", }
    return [NSString stringWithUTF8String:messages[[self getLoggingStatus]]];
}
-(void)setLoggingInterval:(int)ms {
meter_log_settings.rw.logging_period_ms=ms;
    sendlogsettings;
}
-(int)getLoggingIntervalMS {
    return meter_log_settings.rw.logging_period_ms;
}

-(MeterReading*) getValue:(Channel)c {
    switch(c) {
        case CH1:
        case CH2:
            if(((myInputDescriptor *)[self getSelectedDescriptor:c]).is_ac) {
                return [self wrapMeterReading:[self lsbToNativeUnits:sqrt(meter_sample.ch_ms[c]) ch:c] c:c];
            } else {
                return [self wrapMeterReading:[self lsbToNativeUnits:meter_sample.ch_reading_lsb[c] ch:c]+[self getOffset:c].value c:c];
            }
        case MATH:
            MathInputDescriptor id = (MathInputDescriptor)input_descriptors.get(Channel.MATH).getChosen();
            if(id.meterSettingsAreValid()) {
                return id.calculate();
            } else {
                MeterReading rval = invalid_inputs;
                return rval;
            }
    }
    return new MeterReading();
}

-(InputDescriptor*) getSelectedDescriptor:(Channel)c {
    InputDescriptor * rval = [input_descriptors[c] getChosen];
    return rval;
}

-(NSString*) getRangeLabel:(Channel) c;
-(int)         setRange:(Channel)c rd:(id)rd;
-(NSArray<NSString*>*) getRangeList:(Channel)c;

-(NSString*) getInputLabel:(Channel)c;
-(int)setInput:(Channel)c descriptor:(id)descriptor;
-(NSArray *) getInputList:(Channel)c;
-(id) getSelectedDescriptor:(Channel)c;

@end
