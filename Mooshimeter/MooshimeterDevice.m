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

#import "MooshimeterDevice.h"

// A global meter.  TODO: Make this a singleton or something respectable.
MooshimeterDevice* g_meter;

@implementation MooshimeterDevice

@synthesize p;

-(MooshimeterDevice*) init:(LGPeripheral*)periph delegate:(id<MooshimeterDeviceDelegate>)delegate {
    // Check for issues with struct packing.
    BUILD_BUG_ON(sizeof(trigger_settings_t) != 6);
    BUILD_BUG_ON(sizeof(MeterSettings_t)    != 13);
    BUILD_BUG_ON(sizeof(meter_state_t)      != 1);
    BUILD_BUG_ON(sizeof(MeterLogSettings_t) != 16);
    self = [super init];
    self.p = periph;
    self.delegate = delegate;
    self.chars = nil;
    
    self->disp_settings.auto_range[0] = YES;
    self->disp_settings.auto_range[1] = YES;
    self->disp_settings.channel_disp[0] = YES;
    self->disp_settings.channel_disp[1] = YES;
    self->disp_settings.depth_auto = YES;
    self->disp_settings.rate_auto = YES;
    
    self->offset_on  = NO;
    self->ch1_offset = 0;
    self->ch2_offset = 0;
    self->ch3_offset = 0;
    
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
                                            [weakSelf.delegate finishedMeterSetup];
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
                        [self.delegate finishedMeterSetup];
                    }];
                } else {
                    NSLog(@"Service I don't care about found.");
                }
            }
        }];
    }];
}

-(void)accidentalDisconnect:(NSError*)error {
    DLog(@"Accidental disconnect!");
    [self.delegate meterDisconnected];
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

-(void)bumpRange:(int)channel raise:(BOOL)raise wrap:(BOOL)wrap {
    uint8 channel_setting    = [self getChannelSetting:channel];
    uint8* const adc_setting = &self->meter_settings.rw.adc_settings;
    uint8* const ch3_mode    = &self->disp_settings.ch3_mode;
    uint8* const measure_setting = &self->meter_settings.rw.measure_settings;
    int8 tmp;
    
    switch(channel_setting & METER_CH_SETTINGS_INPUT_MASK) {
        case 0x00:
            // Electrode input
            switch(channel) {
                case 1:
                    // We are measuring current.  We can boost PGA, but that's all.
                    channel_setting = [MooshimeterDevice pga_cycle:channel_setting inc:raise wrap:wrap];
                    break;
                case 2:
                    // Switch the ADC GPIO to activate dividers
                    // NOTE: Don't bother with the 1.2V range for now.  Having a floating autoranged input leads to glitchy behavior.
                    tmp = (*adc_setting & ADC_SETTINGS_GPIO_MASK)>>4;
                    if(raise) {
                        if(++tmp >= 3) {
                            if(wrap){tmp=1;}
                            else    {tmp--;}
                        }
                    } else {
                        if(--tmp < 1) {
                            if(wrap){tmp=2;}
                            else    {tmp++;}
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
                    channel_setting = [MooshimeterDevice pga_cycle:channel_setting inc:raise wrap:wrap];
                    break;
                case CH3_RESISTANCE:
                case CH3_DIODE:
                    // This case is annoying.  We want PGA to always wrap if we are in the low range and going up OR in the high range and going down
                    if((raise?0:METER_MEASURE_SETTINGS_ISRC_LVL) ^ (*measure_setting & METER_MEASURE_SETTINGS_ISRC_LVL)) {
                        wrap = YES;
                    }
                    channel_setting = [MooshimeterDevice pga_cycle:channel_setting inc:raise wrap:wrap];
                    tmp = channel_setting & METER_CH_SETTINGS_PGA_MASK;
                    tmp >>=4;
                    if(   ( raise && tmp == 6)
                       || (!raise && tmp == 1) ) {
                        *measure_setting ^= METER_MEASURE_SETTINGS_ISRC_LVL;
                    }
                    break;
            }
            break;
    }
    [g_meter setChannelSetting:channel set:channel_setting];
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
                case 1:
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
                case 2:
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
                    switch(pga_setting) {
                        case 0x60:
                            if(!(*measure_setting&METER_MEASURE_SETTINGS_ISRC_LVL))
                            {return 0.012*(1<<22);}
                            else {return 0;}
                        case 0x40:
                            return 0.33*(1<<22);
                        case 0x10:
                            return 0.25*(1<<22);
                    }
                    break;
            }
            break;
    }
    return 0;
}

-(void)applyAutorange {
    MooshimeterDevice* m = g_meter;
    MeterSettings_t* const ms = &m->meter_settings;
    
    const BOOL ac_used = m->disp_settings.ac_display[0] || m->disp_settings.ac_display[1];
    const int32 upper_limit_lsb =  0.85*(1<<22);
    const int32 lower_limit_lsb = -0.85*(1<<22);
    
    // Autorange sample rate and buffer depth.
    // If anything is doing AC, we need a deep buffer and fast sample
    if(m->disp_settings.rate_auto) {
        ms->rw.adc_settings &=~ADC_SETTINGS_SAMPLERATE_MASK;
        if(ac_used) ms->rw.adc_settings |= 5; // 4kHz
        else        ms->rw.adc_settings |= 0; // 125Hz
    }
    if(m->disp_settings.depth_auto) {
        ms->rw.calc_settings &=~METER_CALC_SETTINGS_DEPTH_LOG2;
        if(ac_used) ms->rw.calc_settings |= 8; // 256 samples
        else        ms->rw.calc_settings |= 5; // 32 samples
    }
    for(uint8 i = 0; i < 2; i++) {
        int32 inner_limit_lsb = 0.7*[self getLowerRange:i+1];
        if(m->disp_settings.auto_range[i]) {
            // Note that the ranges are asymmetrical - we have 1.8V of headroom above and 1.2V below
            int32 mean_lsb;
            double rms_lsb;
            switch(i) {
                case 0:
                    mean_lsb = [MooshimeterDevice to_int32:m->meter_sample.ch1_reading_lsb];
                    rms_lsb = sqrt(m->meter_sample.ch1_ms);
                    break;
                case 1:
                    mean_lsb = [MooshimeterDevice to_int32:m->meter_sample.ch2_reading_lsb];
                    rms_lsb = sqrt(m->meter_sample.ch2_ms);
                    break;
            }
            
            if(   mean_lsb > upper_limit_lsb
               || mean_lsb < lower_limit_lsb
               || rms_lsb*sqrt(2.) > ABS(lower_limit_lsb) ) {
                [m bumpRange:i+1 raise:YES wrap:NO];
            } else if(   ABS(mean_lsb)    < inner_limit_lsb
                      && rms_lsb*sqrt(2.) < inner_limit_lsb ) {
                [m bumpRange:i+1 raise:NO wrap:NO];
            }
        }
    }
}

-(void)handleBufStreamUpdate:(NSData*) data channel:(int)channel {
    static BOOL ch1_last_received = NO;
    static int buf_i = 0;
    uint16 buf_len_bytes = [self getBufLen]*sizeof(int24_test);
    uint8* target;
    NSLog(@"Buf: %d: %d", channel, buf_i);
    if(channel == 1) {
        if(!ch1_last_received){buf_i = 0;}
        ch1_last_received = YES;
        target = (uint8*)self->sample_buf.CH1_buf;
        target+= buf_i;
        [data getBytes:target length:data.length];
        buf_i += data.length;
    } else if(channel == 2) {
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
            [self handleBufStreamUpdate:data channel:2];
        }];
    } onUpdate:^(NSData *data, NSError *error) {
        [self handleBufStreamUpdate:data channel:1];
    }];
}

-(void)setMeterLVMode:(bool)on cb:(LGCharacteristicWriteCallback)cb {
    if(on) {
        self->meter_settings.rw.adc_settings |=  0x10;
    } else {
        self->meter_settings.rw.adc_settings &= ~0x10;
    }
    [self sendMeterSettings:cb];
}

-(void)setMeterHVMode:(bool)on cb:(LGCharacteristicWriteCallback)cb {
    if(on) {
        self->meter_settings.rw.adc_settings |=  0x20;
    } else {
        self->meter_settings.rw.adc_settings &= ~0x20;
    }
    [self sendMeterSettings:cb];
}

-(void)setMeterState:(int)new_state cb:(LGCharacteristicWriteCallback)cb {
    self->meter_settings.rw.target_meter_state = new_state;
    [self sendMeterSettings:cb];
}


+(long)to_int32:(int24_test)arg {
    long int retval;
    memcpy(&retval, &arg, 3);
    ((char*)&retval)[3] = retval & 0x00800000 ? 0xFF:0x00;
    return retval;
}

+(int24_test)to_int24_test:(long)arg {
    int24_test retval;
    memcpy(&retval, &arg, 3);
    return retval;
}

-(int24_test*)getBuf:(int) channel {
    switch(channel) {
        case 1:
            return self->sample_buf.CH1_buf;
        case 2:
            return self->sample_buf.CH2_buf;
        default:
            DLog(@"SHould not be here");
            return self->sample_buf.CH1_buf;
    }
}

-(int)getBufLen {
    return (1<<(self->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2));
}

-(uint8)getChannelSetting:(int)ch {
    switch(ch) {
        case 1:
            return self->meter_settings.rw.ch1set;
        case 2:
            return self->meter_settings.rw.ch2set;
        default:
            DLog(@"Invalid channel");
            return 0;
    }
}

-(void)setChannelSetting:(int)ch set:(uint8)set {
    switch(ch) {
        case 1:
            self->meter_settings.rw.ch1set = set;
            break;
        case 2:
            self->meter_settings.rw.ch2set = set;
            break;
        default:
            DLog(@"Invalid channel");
            break;
    }
}

-(double)getMean:(int)channel {
    int lsb;
    switch(channel) {
        case 1:
            lsb = [MooshimeterDevice to_int32:g_meter->meter_sample.ch1_reading_lsb];
            break;
        case 2:
            lsb = [MooshimeterDevice to_int32:g_meter->meter_sample.ch2_reading_lsb];
            break;
        default:
            lsb = 0;
            DLog(@"Invalid channel");
            break;
    }
    return [self lsbToNativeUnits:lsb ch:channel];
}

-(double)getRMS:(int)channel {
    float lsb;
    switch(channel) {
        case 1:
            lsb = g_meter->meter_sample.ch1_ms;
            break;
        case 2:
            lsb = g_meter->meter_sample.ch2_ms;
            break;
        default:
            lsb = 0;
            DLog(@"Invalid channel");
            break;
    }
    lsb = sqrt(lsb);
    return [self lsbToNativeUnits:lsb ch:channel];
}

-(double)getBufMin:(int)channel {
    int i, tmp;
    int24_test* buf = [self getBuf:channel];
    int min = [MooshimeterDevice to_int32:buf[0]];
    for( i=0; i < [self getBufLen];  i++ ) {
        tmp = [MooshimeterDevice to_int32:buf[i]];
        if(min > tmp) min = tmp;
    }
    return [self lsbToNativeUnits:min ch:channel];
}

-(double)getBufMax:(int)channel {
    int i, tmp;
    int24_test* buf = [self getBuf:channel];
    int max = [MooshimeterDevice to_int32:buf[0]];
    for( i=0; i < [self getBufLen];  i++ ) {
        tmp = [MooshimeterDevice to_int32:buf[i]];
        if(max < tmp) max = tmp;
    }
    return [self lsbToNativeUnits:max ch:channel];
}

/*
 Calculate the mean of the entire sample buffer
 */

-(double)getBufMean:(int)channel {
    int i;
    int avg = 0;
    int24_test* buf = [self getBuf:channel];
    for( i=0; i < [self getBufLen];  i++ ) {
        avg += [MooshimeterDevice to_int32:buf[i]];
    }
    avg /= [self getBufLen];
    return [self lsbToNativeUnits:avg ch:channel];
}

/*
 Accessor for the channel buffers
 @param channel The channel index (0 or 1)
 @return double the value of the sample buffer at that index, in native units (volts, amps, ohms)
 */

-(double)getValAt:(int)channel i:(int)i {
    int24_test* buf = [self getBuf:channel];
    int val = [MooshimeterDevice to_int32:buf[i]];
    return [self lsbToNativeUnits:val ch:channel];
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
    if(channel == 1 && (self->meter_settings.rw.ch1set & METER_CH_SETTINGS_INPUT_MASK) == 0 ) {
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
    const double Vref = 2.5;
    const double pga_lookup[] = {6,1,2,3,4,8,12};
    int pga_setting=0;
    switch(channel) {
        case 1:
            pga_setting = self->meter_settings.rw.ch1set >> 4;
            break;
        case 2:
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
    const double rs = 1e-3;
    const double amp_gain = 80.0;
    return adc_voltage/(amp_gain*rs);
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
    const double isrc_current = [self getIsrcCurrent];
    uint8 channel_setting = [self getChannelSetting:ch] & METER_CH_SETTINGS_INPUT_MASK;
    if(self->disp_settings.raw_hex[ch-1]) {
        return lsb;
    }
    switch(channel_setting) {
        case 0x00:
            // Regular electrode input
            switch(ch) {
                case 1:
                    // FIXME: CH1 offset is treated as an extrinsic offset because it's dominated by drift in the isns amp
                    adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                    adc_volts -= self->ch1_offset;
                    return [self adcVoltageToCurrent:adc_volts];
                case 2:
                    lsb -= self->ch2_offset;
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
            if( isrc_current != 0 ) {
                // Current source is on, apply compensation for PTC drop
                adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
                adc_volts -= ptc_resistance*isrc_current;
                adc_volts -= ch3_offset*isrc_current;
            } else {
                // Current source is off, offset is intrinsic
                lsb -= ch3_offset;
                adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
            }
            if(disp_settings.ch3_mode == CH3_RESISTANCE) {
                return adc_volts/isrc_current;
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
                case 1:
                    if(self->disp_settings.ac_display[channel-1]){
                        return @"Current AC";
                    } else {
                        return @"Current DC";
                    }
                case 2:
                    if(self->disp_settings.ac_display[channel-1]){
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
                    if(self->disp_settings.ac_display[channel-1]){
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
    if(self->disp_settings.raw_hex[channel-1]) {
        return @"RAW";
    }
    switch( channel_setting ) {
        case 0x00:
            switch (channel) {
                case 1:
                    return @"A";
                case 2:
                    return @"V";
                default:
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
                case 1:
                    return @"A";
                case 2:
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
    tmp = [self.p.advertisingData valueForKey:@"kCBAdvDataManufacturerData"];
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

/*
 Clears the stored offsets.  Does not interact with the meter.
 */

-(void)clearOffsets {
    offset_on = NO;
    self->ch1_offset = 0;
    self->ch2_offset = 0;
    self->ch3_offset = 0;
}

/*
 Take the value of the auxiliary channel and save it as the ch3_offset.
 Depending on the channel settings, ch3_offset can be stored as a resistance or as a voltage.
 */

-(void)auxZero:(int)c {
    int24_test tmp;
    int lsb;
    if(c==0) { tmp = meter_sample.ch1_reading_lsb; }
    else     { tmp = meter_sample.ch2_reading_lsb; }
    lsb = [MooshimeterDevice to_int32:tmp];
    if( meter_settings.rw.measure_settings & METER_MEASURE_SETTINGS_ISRC_ON ) {
        double isrc_current = [self getIsrcCurrent];
        // Save aux offset as a resistance
        self->ch3_offset = [self lsbToNativeUnits:lsb ch:c+1]; // FIXME: Inconsistent channel addressing
        if( disp_settings.ch3_mode != CH3_RESISTANCE ) {
            self->ch3_offset /= isrc_current;
        }
    } else {
            // Current source is off, save as a simple voltage offset
            self->ch3_offset = lsb;
    }
}

-(void)setZero {
    // FIXME:  Annoying hack:  CH1 offset is dominated by extrinsic because of isns amp, but others are dominated by intrinsic
    // To deal with this, ch1_offset will be in extrinsic units, but CH2 and CH3 will be in lsb
    if( (self->meter_settings.rw.ch1set & METER_CH_SETTINGS_INPUT_MASK) == 0x09 ) {
        [self auxZero:0];
    } else {
        self->ch1_offset = [self lsbToADCInVoltage:[MooshimeterDevice to_int32:self->meter_sample.ch1_reading_lsb] channel:1];
    }
    if( (self->meter_settings.rw.ch2set & METER_CH_SETTINGS_INPUT_MASK) == 0x09 ) {
        [self auxZero:1];
    } else {
        self->ch2_offset = [MooshimeterDevice to_int32:self->meter_sample.ch2_reading_lsb];
    }
}

@end
