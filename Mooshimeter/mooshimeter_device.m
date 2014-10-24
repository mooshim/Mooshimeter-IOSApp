//
//  mooshimeter_device.m
//
//  James Whong 2013
//  Bla bla legalese will sue you don't steal bla bla
// There is no word in hippo for mercy
//

#import "mooshimeter_device.h"

@implementation mooshimeter_device

@synthesize p;
@synthesize manager;

-(mooshimeter_device*) init:(CBCentralManager*)man periph:(CBPeripheral*)periph {
    // Check for issues with struct packing.
    BUILD_BUG_ON(sizeof(trigger_settings_t)!=5);
    BUILD_BUG_ON(sizeof(MeterSettings_t)!=4);
    BUILD_BUG_ON(sizeof(meter_state_t) != 1);
    BUILD_BUG_ON(sizeof(buf_i) != 2);
    self = [super init];
    self.cbs = [[NSMutableDictionary alloc] init];
    self.manager = man;
    self.p = periph;
    return self;
}

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb {
    [self createCB:key target:target cb:cb arg:[NSNull null]];
}

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:key target:target cb:cb arg:arg oneshot:YES];
}

-(void) createCB:(NSString*)key target:(id)target cb:(SEL)cb arg:(id)arg oneshot:(BOOL)oneshot {
    NSLog(@"Creating cb %@", key);
    if( target == nil ) {
        return;
    }
    if( arg == nil ) {
        arg = [NSNull null];
    }
    NSArray* val = [NSArray arrayWithObjects:target, [NSValue valueWithPointer:cb], arg, [NSNumber numberWithBool:oneshot], nil];
    [self.cbs setObject:val forKey:key];
}

-(void) clearCB:(NSString*)key {
    [self.cbs removeObjectForKey:key];
}

-(void) callCB:(NSString*)key {
    NSArray *val = [self.cbs objectForKey:key];
    NSLog(@"Calling %@", key);
    if( val == nil ) {
        NSLog(@"No callback registered for %@!", key);
        return;
    }
    id target  = [val objectAtIndex:0];
    NSValue* cb_wrap = [val objectAtIndex:1];
    id arg = [val objectAtIndex:2];
    BOOL oneshot = [[val objectAtIndex:3] boolValue];
    SEL cb = [cb_wrap pointerValue];
    
    if(oneshot) {
        [self.cbs removeObjectForKey:key];
    }
    
    if( [target respondsToSelector:cb] ) {
        if( arg == [NSNull null] ) {
            [target performSelector:cb];
        } else {
            [target performSelector:cb withObject:arg];
        }
    } else {
        NSLog(@"Target does not respond to selector!");
    }
}

-(BOOL) checkCB:(NSString*)key {
    NSArray *val = [self.cbs objectForKey:key];
    return val != nil;
}

-(void)setup:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"setup" target:target cb:cb arg:arg];
    [self.manager connectPeripheral:self.p options:nil];
}

-(void)reconnect:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"reconnect" target:target cb:cb arg:arg];
    [self.manager connectPeripheral:self.p options:nil];
}

-(void)disconnect {
    [self clearCB:@"disconnect"];
    [self.manager cancelPeripheralConnection:self.p];
}

-(void)registerDisconnectCB:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"disconnect" target:target cb:cb arg:arg];
}

-(void)reqMeterInfo:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"info" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p cUUID:0xFFA1];
}

-(void)reqMeterSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"settings" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p cUUID:0xFFA5];
}

-(void)sendMeterSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_settings" target:target cb:cb arg:arg];
    [BLEUtility writeCharacteristic:self.p cUUID:0xFFA5 data:[NSData dataWithBytes:(char*)(&self->meter_settings) length:sizeof(self->meter_settings)]];
}

-(void)reqADCSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"adc_settings" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p cUUID:0xFFA6];
}

-(void)sendADCSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_adc_settings" target:target cb:cb arg:arg];
    // Sanitize the ADC register settings - make sure all mandatory bits are set to their mandatory position
    // See ADS1292 datasheet for more details
#define SET_W_MASK(target, val, mask) target ^= (mask)&((val)^target)
    const uint8 mand_bits[] = ADS1x9x_MANDATORY_BITS;
    const uint8 mand_mask[] = ADS1x9x_MANDATORY_BITS_MASK;
    for(int i = 0; i < sizeof(ADS1x9x_registers_t); i++) {
        SET_W_MASK(self->ADC_settings.bytes[i], mand_bits[i], mand_mask[i]);
    }
#undef SET_W_MASK
    [BLEUtility writeCharacteristic:self.p cUUID:0xFFA6 data:[NSData dataWithBytes:(char*)(&self->ADC_settings) length:sizeof(self->ADC_settings)]];
}

-(void)reqMeterSample:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p cUUID:0xFFA2];
}

-(void)startStreamMeterSample:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample" target:target cb:cb arg:arg oneshot:NO];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:0xFFA2 enable:YES];
}

-(void)stopStreamMeterSample {
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:0xFFA2 enable:NO];
}

-(void)startStreamMeterBuf:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"buf_stream" target:target cb:cb arg:arg];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:0xFFA4 enable:YES];
}

-(void)stopStreamMeterBuf {
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:0xFFA4 enable:NO];
}

-(void)enableADCSettingsNotify:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"adc_settings_stream" target:target cb:cb arg:arg];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:0xFFA6 enable:YES];
}

-(void)setMeterLVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg {
    if(on) {
        self->ADC_settings.str.gpio |=  0x01;
    } else {
        self->ADC_settings.str.gpio &= ~0x01;
    }
    [self sendADCSettings:target cb:cb arg:arg];
}

-(void)setMeterHVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg {
    if(on) {
        self->ADC_settings.str.gpio |=  0x02;
    } else {
        self->ADC_settings.str.gpio &= ~0x02;
    }
    [self sendADCSettings:target cb:cb arg:arg];
}

-(void)downloadSampleBuffer:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample_buf_downloaded" target:target cb:cb arg:arg];
    self->buf_i = 0;
    [self setMeterState:METER_ONESHOT target:self cb:@selector(bufferDownloadController:) arg:arg];
}
#if 0
-(void)bufferDownloadController:(NSNumber*)state {
    int s_int = [state intValue];
    NSNumber* arg = [NSNumber numberWithInt:s_int+1];
    if( s_int == 0 ) {
        [self setMeterState:METER_ONESHOT target:self cb:@selector(bufferDownloadController:) arg:arg];
    } else if( s_int == 1 ) {
        NSLog(@"Setting sample_buf_i to 0");
        self->buf_i = 0;
        [self sendSampleBufferI:0 target:self cb:@selector(bufferDownloadController:) arg:arg];
    } else if ( self->buf_i < 2*(1<<(self->meter_settings.calc_settings&METER_CALC_SETTINGS_DEPTH_LOG2)) ) {
        /* There is still more buffer to download */
        [self reqSampleBuffer:self cb:@selector(bufferDownloadController:) arg:arg];
    } else {
        [self setMeterState:METER_RUNNING target:nil cb:nil arg:nil];
        [self callCB:@"sample_buf_downloaded"];
    }
}
#endif

-(void)setMeterState:(int)new_state target:(id)target cb:(SEL)cb arg:(id)arg{
    self->meter_settings.target_meter_state = new_state;
    [self sendMeterSettings:target cb:cb arg:arg];
}

-(int)getMeterState {
    return 0;
}

-(MeterMeasurement_t)getMeterReading {
    MeterMeasurement_t retval;
    return retval;
}

#pragma mark - CBCentralManager delegate function

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Meter connected");
    peripheral.delegate = self;
    if( [self checkCB:@"setup"] ) {
        [self createCB:@"discover" target:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:0]];
    } else {
        [self createCB:@"discover" target:self cb:@selector(restoreSettings:) arg:[NSNumber numberWithInt:0]];
    }
    [peripheral discoverServices:nil];
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnected!");
    NSLog(@"%@", error.localizedDescription);
    [self callCB:@"disconnect"];
}

#pragma mark - CBperipheral delegate functions

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"..");
    if( [service.UUID isEqual:[BLEUtility expandToMooshimUUID:0xFFA0]] ) {
        NSLog(@"Discovered characteristics for Mooshimeter!");
        [self callCB:@"discover"];
    }
}

#define UUID_EQUALS( uuid ) [characteristic.UUID isEqual:[BLEUtility expandToMooshimUUID:(uuid)]]

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@".");
    for (CBService *s in peripheral.services) [peripheral discoverCharacteristics:nil forService:s];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@, error = %@",characteristic.UUID, error);
    
    if( UUID_EQUALS(0xFFA2)) {
        [self callCB:@"sample"];
    } else if( UUID_EQUALS(0xFFA4)) {
        [self callCB:@"buf_stream"];
    } else if( UUID_EQUALS(0xFFA6)) {
        [self callCB:@"adc_settings_stream"];
    } else  {
        NSLog(@"We read something I don't recognize...");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    NSLog(@"didUpdateValueForCharacteristic = %@",characteristic.UUID);
    
    unsigned char buf[characteristic.value.length];
    [characteristic.value getBytes:&buf length:characteristic.value.length];
    
    if(        UUID_EQUALS(0xFFA1) ) {
        NSLog(@"Received Meter Info: %lu", (unsigned long)characteristic.value.length);
        [characteristic.value getBytes:&self->meter_info length:characteristic.value.length];
        [self callCB:@"info"];
        
    } else if( UUID_EQUALS(0xFFA2)) {
        NSLog(@"Read sample");
        [characteristic.value getBytes:&self->meter_sample length:characteristic.value.length];
        [self callCB:@"sample"];
        
    } else if( UUID_EQUALS(0xFFA4)) {
        NSLog(@"Read buf: %d", self->buf_i);
        uint8 tmp[20];
        uint16 channel_buf_len_bytes = [self getBufLen]*sizeof(int24_test);
        [characteristic.value getBytes:tmp range:NSMakeRange(0, characteristic.value.length)];
        for(int i=0; i < characteristic.value.length; i++) {
            if( self->buf_i < channel_buf_len_bytes) {
                // Write to CH1
                ((uint8*)(self->sample_buf.CH1_buf))[buf_i] = tmp[i];
            } else if( self->buf_i < 2*channel_buf_len_bytes) {
                // Write to CH2
                ((uint8*)(self->sample_buf.CH2_buf))[buf_i-channel_buf_len_bytes] = tmp[i];
            }
            self->buf_i++;
        }
        if(self->buf_i >= 2*channel_buf_len_bytes) {
            // We downloaded the whole sample buffer
            [self callCB:@"sample_buf_downloaded"];
        }
    } else if( UUID_EQUALS(0xFFA5)) {
        NSLog(@"Read meter settings: %lu", (unsigned long)characteristic.value.length);
        [characteristic.value getBytes:&self->meter_settings length:characteristic.value.length];
        [self callCB:@"settings"];
        
    } else if( UUID_EQUALS(0xFFA6)) {
        NSLog(@"Read adc settings");
        [characteristic.value getBytes:&self->ADC_settings length:characteristic.value.length];
        [self callCB:@"adc_settings"];
        
    } else  {
        NSLog(@"We read something I don't recognize...");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic.UUID,error);
    
    if( UUID_EQUALS(0xFFA5) ) {
        [self callCB:@"write_settings"];
    } else if( UUID_EQUALS(0xFFA6)) {
        [self callCB:@"write_adc_settings"];
    }
}
#undef UUID_EQUALS

-(long)to_int32:(int24_test)arg {
    long int retval;
    memcpy(&retval, &arg, 3);
    ((char*)&retval)[3] = retval & 0x00800000 ? 0xFF:0x00;
    return retval;
}

-(int24_test)to_int24_test:(long)arg {
    int24_test retval;
    memcpy(&retval, &arg, 3);
    return retval;
}

#define SET_W_MASK(target, val, mask) target ^= (mask)&((val)^target)

-(void) doSetup:(NSNumber*)stage {
    NSLog(@"In doSetup: stage %d", [stage intValue]);
    int next = [stage intValue];
    switch( next++ ) {
        case 0:
            [self reqMeterInfo:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 1:
            [self reqMeterSettings:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 2:
            [self reqADCSettings:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 3:
            // Take the voltage channel out of high precision mode to begin with, this confuses users.
            SET_W_MASK( self->ADC_settings.str.gpio  , 0x01, 0X03);
            [self sendADCSettings:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 4:
            // Enable notifications for the sample buffer (necessary to stream)
            [self startStreamMeterBuf:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 5:
            // Enable notifications for the ADC settings structure (necessary to properly autorange)
            [self enableADCSettingsNotify:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 6:
            [self callCB:@"setup"];
            break;
        default:
            NSLog(@"in doSetup ended up somewhere impossible");
    }
}

-(void) restoreSettings:(NSNumber*)stage {
   NSLog(@"In restore: stage %d", [stage intValue]);
   int next = [stage intValue];
   switch( next++ ) {
       case 0:
           [self sendADCSettings:self cb:@selector(restoreSettings:) arg:[NSNumber numberWithInt:next]];
           break;
       case 1:
           [self sendMeterSettings:self cb:@selector(restoreSettings:) arg:[NSNumber numberWithInt:next]];
           break;
       case 2:
           [self callCB:@"reconnect"];
           break;
       default:
           NSLog(@"in restore ended up somewhere impossible");
   }
}

-(int)getBufLen {
    return (1<<(self->meter_settings.calc_settings&METER_CALC_SETTINGS_DEPTH_LOG2));
}

-(int)getBufMin:(int24_test*)buf {
    int i, tmp;
    int min = [self to_int32:buf[0]];
    for( i=0; i < 32;  i++ ) {
        tmp = [self to_int32:buf[i]];
        if(min > tmp) min = tmp;
    }
    return min;
}

-(double)getCH1BufMin {
    return [self calibrateCH1Value:[self getBufMin:self->sample_buf.CH1_buf] offset:YES];
}
-(double)getCH2BufMin {
    return [self calibrateCH2Value:[self getBufMin:self->sample_buf.CH2_buf] offset:YES];
}

-(int)getBufMax:(int24_test*)buf {
    int i, tmp;
    int max = [self to_int32:buf[0]];
    for( i=0; i < 32;  i++ ) {
        tmp = [self to_int32:buf[i]];
        if(max < tmp) max = tmp;
    }
    return max;
}

-(double)getCH1BufMax {
    return [self calibrateCH1Value:[self getBufMax:self->sample_buf.CH1_buf] offset:YES];
}
-(double)getCH2BufMax {
    return [self calibrateCH2Value:[self getBufMax:self->sample_buf.CH2_buf] offset:YES];
}

-(double)calibrateCH1Value:(int)reading offset:(BOOL)offset{
    double base = (double)reading;
    double Rs   = 1e-3;
    double amp_gain = 80.0;
    double Vref = 2.5;
    double R1   = 1008;
    double R2   = 10e3;
    const double pga_lookup[] = {6,1,2,3,4,8,12};
    
    /* Figure out what our measurement mode is */
    double pga_gain = pga_lookup[self->ADC_settings.str.ch1set >> 4];
    double c_gain = 1.0;
    double c_offset = 0.0;
    switch( self->ADC_settings.str.ch1set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            c_gain = (1.0/amp_gain)*(1/(Rs)) * Vref / (1<<23);
            break;
        case 0x03:
            // Power supply measurement
            c_gain = 2*Vref/(1<<23);
            break;
        case 0x04:
            // Temperature sensor
            c_gain   = (1./490e-6)*Vref/(1<<23);
            c_offset = 270.918367;
            break;
        case 0x09:
            // Channel 3 in
            c_gain     = Vref/(1<<23);
            break;
        default:
            NSLog(@"Unrecognized CH1SET setting");
    }
    base /= pga_gain;
    base *= c_gain;
    if(offset)
        base -= c_offset;
    
    // Apply display settings.  Right now only matters for CH3
    switch( self->ADC_settings.str.ch1set & 0x0F ) {
        case 0x09:
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    break;
                case CH3_RESISTANCE:
                    // Interpret resistance.  Output in ohms.
                    base = R2*(((Vref/2)/((Vref/2)+base))-1.0) - R1;
                    break;
                case CH3_DIODE:
                    break;
            }
            break;
    }
    return base;
}

-(double)getCH1Value {
    int24_test base = self->meter_sample.ch1_reading_lsb;
    return [self calibrateCH1Value:[self to_int32:base] offset:YES];
}

-(double)getCH1Value:(int)index {
    int24_test base = self->sample_buf.CH1_buf[index];
    return [self calibrateCH1Value:[self to_int32:base] offset:YES];
}

-(double)getCH1ACValue {
    unsigned long long ms = self->meter_sample.ac_ch1_ms << 16;
    double rms = sqrt(ms);
    return [self calibrateCH1Value:(int)rms offset:NO];
}

-(NSString*)getCH1Label {
    switch( self->ADC_settings.str.ch1set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            return @"CH1 Current";
            break;
        case 0x03:
            // Power supply measurement
            return @"Battery Voltage";
            break;
        case 0x04:
            // Temperature sensor
            return @"CH1 Temperature";
            break;
        case 0x09:
            // Channel 3 in
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    return @"Ω Voltage";
                case CH3_RESISTANCE:
                    return @"Ω Resistance";
                case CH3_DIODE:
                    return @"Ω Diode";
            }
            break;
        default:
            NSLog(@"Unrecognized CH1SET setting");
            return @"";
    }
}
-(NSString*)getCH1Units {
    switch( self->ADC_settings.str.ch1set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            return @"A";
            break;
        case 0x03:
            // Power supply measurement
            return @"V";
            break;
        case 0x04:
            // Temperature sensor
            return @"C";
            break;
        case 0x09:
            // Channel 3 in
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

-(double)calibrateCH2Value:(int)reading offset:(BOOL)offset {
    double Vref = 2.5;
    double R1   = 1008;
    double R2   = 10e3;
    const double pga_lookup[] = {6,1,2,3,4,8,12};
    
    double base = (double)reading;
    /* Figure out what our measurement mode is */
    double pga_gain = pga_lookup[self->ADC_settings.str.ch2set >> 4];
    double c_gain = 1.0;
    double c_offset = 0.0;
    
    switch( self->ADC_settings.str.ch2set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            switch( self->ADC_settings.str.gpio & 0x03 ) {
                case 0x00:
                    // 1.2V range
                    c_gain = Vref / (1<<23);
                    break;
                case 0x01:
                    // 60V range
                    c_gain = ((10e6+160e3)/(160e3)) * Vref / (1<<23);
                    break;
                case 0x02:
                    // 1000V range
                    c_gain = ((10e6+11e3)/(11e3)) * Vref / (1<<23);
                    break;
            }
            break;
        case 0x03:
            // Power supply measurement
            c_gain = 4*Vref/(1<<23);
            break;
        case 0x04:
            // Temperature sensor
            c_gain   = (1./490e-6)*Vref/(1<<23);
            c_offset = 270.918367;
            break;
        case 0x09:
            // Channel 3 in
            c_gain     = Vref/(1<<23);
            break;
        default:
            NSLog(@"Unrecognized CH2SET setting");
    }
    base /= pga_gain;
    base *= c_gain;
    if(offset)
        base -= c_offset;
    
    // Apply display settings.  Right now only matters for CH3
    switch( self->ADC_settings.str.ch2set & 0x0F ) {
        case 0x09:
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    break;
                case CH3_RESISTANCE:
                    // Interpret resistance.  Output in ohms.
                    base = R2*(((Vref/2)/((Vref/2)+base))-1.0) - R1;
                    break;
                case CH3_DIODE:
                    break;
            }
            break;
    }
    return base;
}

-(double)getCH2Value {
    int24_test base = self->meter_sample.ch2_reading_lsb;
    return [self calibrateCH2Value:[self to_int32:base] offset:YES];
}

-(double)getCH2Value:(int)index {
    int24_test base = self->sample_buf.CH2_buf[index];
    return [self calibrateCH2Value:[self to_int32:base] offset:YES];
}

-(double)getCH2ACValue {
    unsigned long long ms = self->meter_sample.ac_ch2_ms << 16;
    double rms = sqrt(ms);
    return [self calibrateCH2Value:(int)rms offset:NO];
}

-(NSString*)getCH2Label {
    switch( self->ADC_settings.str.ch2set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            return @"CH2 Voltage";
            break;
        case 0x03:
            // Power supply measurement
            return @"CH2 Battery Voltage";
            break;
        case 0x04:
            // Temperature sensor
            return @"CH2 Temperature";
            break;
        case 0x09:
            // Channel 3 in
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    return @"Ω Voltage";
                case CH3_RESISTANCE:
                    return @"Ω Resistance";
                case CH3_DIODE:
                    return @"Ω Diode";
            }
            break;
        default:
            NSLog(@"Unrecognized CH2SET setting");
            return @"";
    }
}
    
-(NSString*)getCH2Units {
    switch( self->ADC_settings.str.ch2set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            return @"V";
            break;
        case 0x03:
            // Power supply measurement
            return @"V";
            break;
        case 0x04:
            // Temperature sensor
            return @"C";
            break;
        case 0x09:
            // Channel 3 in
            switch( self->disp_settings.ch3_mode ) {
                case CH3_VOLTAGE:
                    return @"V";
                case CH3_RESISTANCE:
                    return @"Ω";
                case CH3_DIODE:
                    return @"V";
            }
            break;
        default:
            NSLog(@"Unrecognized CH1SET setting");
            return @"";
    }
}


@end
