//
//  mooshimeter_device.m
//
//  James Whong 2013
//  Bla bla legalese will sue you don't steal bla bla
// There is no word in hippo for mercy
//

#import "MooshimeterDevice.h"

// A global meter.  Because fuck you.
MooshimeterDevice* g_meter;

@implementation MooshimeterDevice

@synthesize p;

-(MooshimeterDevice*) init:(LGPeripheral*)periph delegate:(id<MooshimeterDeviceDelegate>)delegate {
    // Check for issues with struct packing.
    BUILD_BUG_ON(sizeof(trigger_settings_t)!=6);
    BUILD_BUG_ON(sizeof(MeterSettings_t)!=13);
    BUILD_BUG_ON(sizeof(meter_state_t) != 1);
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
    
    return self;
}

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
                        [self populateLGDict:characteristics];
                        [self reqMeterInfo:^(NSData *data, NSError *error) {
                            [self reqMeterSettings:^(NSData *data, NSError *error) {
                                [self.p registerDisconnectHandler:^(NSError *error) {
                                    [self accidentalDisconnect:error];
                                }];
                                [self.delegate finishedMeterSetup];
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

-(void)reqMeterInfo:(LGCharacteristicReadCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_INFO];
    [c readValueWithBlock:^(NSData *data, NSError *error) {
        [data getBytes:&self->meter_info length:data.length];
        cb(data,error);
    }];
}

-(void)reqMeterSettings:(LGCharacteristicReadCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_SETTINGS];
    [c readValueWithBlock:^(NSData *data, NSError *error) {
        [data getBytes:&self->meter_settings length:data.length];
        cb(data,error);
    }];
}

-(void)reqMeterSample:(LGCharacteristicReadCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_SAMPLE];
    [c readValueWithBlock:^(NSData *data, NSError *error) {
        [data getBytes:&self->meter_sample length:data.length];
        cb(data,error);
    }];
}

-(void)sendMeterSettings:(LGCharacteristicWriteCallback)cb {
    LGCharacteristic* c = [self getLGChar:METER_SETTINGS];
    NSData* v = [NSData dataWithBytes:&self->meter_settings length:sizeof(self->meter_settings)];
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

-(double)getValAt:(int)channel i:(int)i {
    int24_test* buf = [self getBuf:channel];
    int val = [MooshimeterDevice to_int32:buf[i]];
    return [self lsbToNativeUnits:val ch:channel];
}

-(double)getENOB:(int)channel {
    // Return a rough appoximation of the ENOB of the channel
    // For the purposes of figuring out how many digits to display
    // Based on ADS1292 datasheet and some special sauce.
    // And empirical measurement of CH1 (which is super noisy due to chopper)
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
    double pga_degradation = (1.5/12) * pga_gain * (samplerate_setting);
    enob -= pga_degradation;
    // Oversampling adds 1 ENOB per factor of 4
    enob += ((double)buffer_depth_log2)/2.0;
    //
    if(channel == 1 && (self->meter_settings.rw.ch1set & METER_CH_SETTINGS_INPUT_MASK) == 0 ) {
        // This is compensation for a bug in RevH, where current sense chopper noise dominates
        enob -= 3;
    }
    return enob;
}

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

-(double)adcVoltageToCurrent:(double)adc_voltage {
    const double rs = 1e-3;
    const double amp_gain = 80.0;
    return adc_voltage/(amp_gain*rs);
}

-(double)adcVoltageToTemp:(double)adc_voltage {
    adc_voltage -= 145.3e-3; // 145.3mV @ 25C
    adc_voltage /= 490e-6;   // 490uV / C
    return 25.0 + adc_voltage;
}

-(double)lsbToNativeUnits:(int)lsb ch:(int)ch {
    double adc_volts = [self lsbToADCInVoltage:lsb channel:ch];
    uint8 channel_setting = [self getChannelSetting:ch] & METER_CH_SETTINGS_INPUT_MASK;
    if(self->disp_settings.raw_hex[ch-1]) {
        return lsb;
    }
    switch(channel_setting) {
        case 0x00:
            // Regular electrode input
            switch(ch) {
                case 1:
                    return [self adcVoltageToCurrent:adc_volts];
                case 2:
                    return [self adcVoltageToHV:adc_volts];
                default:
                    DLog(@"Invalid channel");
                    return 0;
            }
        case 0x04:
            return [self adcVoltageToTemp:adc_volts];
        case 0x09:
            // TODO: In this area we have some interpretting of display settings to do, for things like diode or resistance measurement.
            return adc_volts;
        default:
            DLog(@"Unrecognized channel setting");
            return adc_volts;
    }
}

-(NSString*)getDescriptor:(int)channel {
    uint8 channel_setting = [self getChannelSetting:channel] & METER_CH_SETTINGS_INPUT_MASK;
    switch( channel_setting ) {
        case 0x00:
            switch (channel) {
                case 1:
                    switch(self->disp_settings.ac_display[channel-1]){
                        case NO:
                            return @"Current DC";
                        case YES:
                            return @"Current AC";
                    }
                case 2:
                    switch(self->disp_settings.ac_display[channel-1]){
                        case NO:
                            return @"Voltage DC";
                        case YES:
                            return @"Voltage AC";
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
                    switch(self->disp_settings.ac_display[channel-1]){
                        case NO:
                            return @"Aux Voltage DC";
                        case YES:
                            return @"Aux Voltage AC";
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

@end
