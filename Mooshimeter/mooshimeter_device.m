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
    BUILD_BUG_ON(sizeof(MeterSettings_t)!=9);
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

-(void)setup:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"setup" target:target cb:cb arg:arg];
    [self.manager connectPeripheral:self.p options:nil];
}

-(void)disconnect:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"disconnect" target:target cb:cb arg:arg];
    [self.manager cancelPeripheralConnection:self.p];
}

-(void)registerDisconnectCB:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"disconnect" target:target cb:cb arg:arg];
}

-(void)reqMeterInfo:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"info" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA1"];
}

-(void)reqMeterSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"settings" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA6"];
}

-(void)sendMeterSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_settings" target:target cb:cb arg:arg];
    [BLEUtility writeCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA6" data:[NSData dataWithBytes:(char*)(&self->meter_settings) length:sizeof(self->meter_settings)]];
}

-(void)reqADCSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"adc_settings" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA7"];
}

-(void)sendADCSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_adc_settings" target:target cb:cb arg:arg];
    [BLEUtility writeCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA7" data:[NSData dataWithBytes:(char*)(&self->ADC_settings) length:sizeof(self->ADC_settings)]];
}

-(void)reqCalPoint:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"cal_point" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA8"];
}

-(void)reqMeterSample:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA2"];
}

-(void)startStreamMeterSample:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample" target:target cb:cb arg:arg oneshot:NO];
    [BLEUtility setNotificationForCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA2" enable:YES];
}

-(void)stopStreamMeterSample {
    [BLEUtility setNotificationForCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA2" enable:NO];
}

-(void)downloadCalPoint:(int)i target:(id)target cb:(SEL)cb arg:(id)arg {
    NSLog(@"Starting download of cal point %d", i);
    [self createCB:@"cal_downloaded" target:target cb:cb arg:arg];
    [self calPointDownloadController:YES reset_i:i];
}

-(void)calPointDownloadControllerCB {
    [self calPointDownloadController:NO reset_i:0 ];
}

-(void)calPointDownloadController:(BOOL)reset reset_i:(int)reset_i {
    static int state = 0;
    static int i;
    if(reset) {
        state = 0;
        i = reset_i;
    }
    switch(state++) {
        case 0:
            [self sendCalI:(i*36) target:self cb:@selector(calPointDownloadControllerCB) arg:nil];
            break;
        case 1:
            [self reqCalPoint:self cb:@selector(calPointDownloadControllerCB) arg:nil];
            break;
        case 2:
            [self sendCalI:(i*36 + 18) target:self cb:@selector(calPointDownloadControllerCB) arg:nil];
            break;
        case 3:
            [self reqCalPoint:self cb:@selector(calPointDownloadControllerCB) arg:nil];
            break;
        case 4:
            [self callCB:@"cal_downloaded"];
            break;
    }
}

-(void)setMeterHVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg {
    if(on) {
        self->ADC_settings.str.gpio |=  0x01;
    } else {
        self->ADC_settings.str.gpio &= ~0x01;
    }
    [self sendADCSettings:target cb:cb arg:arg];
}

-(void)setMeterCH3PullDown:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg {
    if(on) {
        self->ADC_settings.str.gpio |=  0x02;
    } else {
        self->ADC_settings.str.gpio &= ~0x02;
    }
    [self sendADCSettings:target cb:cb arg:arg];
}

-(void)sendCalI:(unsigned char)i target:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_cal_i" target:target cb:cb arg:[NSNumber numberWithInt:i]];
    [BLEUtility writeCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA9" data:[NSData dataWithBytes:&i length:1]];
    self->cal_i = i;
}

-(void)sendSampleBufferI:(int)i target:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_sample_buf_i" target:target cb:cb arg:arg];
    [BLEUtility writeCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA5" data:[NSData dataWithBytes:&i length:2]];
}

-(void)doCal:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"cal_complete" target:target cb:cb arg:arg];
    self->meter_settings.target_meter_state = METER_CALIBRATING;
    [self sendMeterSettings:nil cb:nil arg:nil];
    [self performSelector:@selector(afterCalCleanup) withObject:nil afterDelay:4.0];
}

-(void)afterCalCleanup {
    [self downloadCalPoint:6 target:self cb:@selector(callCB:) arg:@"cal_complete"];
}

-(void)saveCalToNV:(int)i target:(id)target cb:(SEL)cb arg:(id)arg {
    self->meter_settings.cal_setting.cal_target = i;
    self->meter_settings.cal_setting.save = 1;
    [self sendMeterSettings:target cb:cb arg:arg];
    // Really we should re-download cal data from the meter, but let's just cheat and copy
    // locally FIXME
    self->meter_cal[i] = self->meter_cal[6];
}

-(void)reqSampleBuffer:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample_buf" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p sUUID:@"FFA0" cUUID:@"FFA4"];
}

-(void)downloadSampleBuffer:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample_buf_downloaded" target:target cb:cb arg:arg];
    [self bufferDownloadController:[NSNumber numberWithInt:0]];
}

-(void)bufferDownloadController:(NSNumber*)state {
    int s_int = [state intValue];
    NSNumber* arg = [NSNumber numberWithInt:s_int+1];
    if( s_int == 0 ) {
        [self setMeterState:METER_ONESHOT target:self cb:@selector(bufferDownloadController:) arg:arg];
    } else if( s_int == 1 ) {
        NSLog(@"Setting sample_buf_i to 0");
        self->buf_i = 0;
        [self sendSampleBufferI:0 target:self cb:@selector(bufferDownloadController:) arg:arg];
    } else if ( self->buf_i < 2*(1<<self->meter_settings.buf_depth_log2) ) {
        /* There is still more buffer to download */
        [self reqSampleBuffer:self cb:@selector(bufferDownloadController:) arg:arg];
    } else {
        [self setMeterState:METER_RUNNING target:nil cb:nil arg:nil];
        [self callCB:@"sample_buf_downloaded"];
    }
}

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
    [self createCB:@"discover" target:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:0]];
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
    if( [service.UUID isEqual:[CBUUID UUIDWithString:(@"FFA0")]] ) {
        NSLog(@"Discovered characteristics for Mooshimeter!");
        [self callCB:@"discover"];
    }
}

#define UUID_EQUALS( uuid ) [characteristic.UUID isEqual:[CBUUID UUIDWithString:(uuid)]]

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@".");
    for (CBService *s in peripheral.services) [peripheral discoverCharacteristics:nil forService:s];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@, error = %@",characteristic.UUID, error);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    NSLog(@"didUpdateValueForCharacteristic = %@",characteristic.UUID);
    
    unsigned char buf[characteristic.value.length];
    [characteristic.value getBytes:&buf length:characteristic.value.length];
    
    if(        UUID_EQUALS(@"FFA1" ) ) {
        NSLog(@"Received Meter Info: %d", characteristic.value.length);
        [characteristic.value getBytes:&self->meter_info length:characteristic.value.length];
        [self callCB:@"info"];
        
    } else if( UUID_EQUALS(@"FFA2")) {
        NSLog(@"Read sample");
        [characteristic.value getBytes:&self->meter_sample length:characteristic.value.length];
        [self callCB:@"sample"];
        
    } else if( UUID_EQUALS(@"FFA4")) {
        NSLog(@"Read buf: %d", self->buf_i);
        int overshoot = ((self->buf_i + 6) * sizeof(int24_test)) - sizeof(self->sample_buf);
        overshoot = overshoot>0 ? overshoot:0;
        [characteristic.value getBytes:((char*)(&self->sample_buf) + 3*(self->buf_i)) range:NSMakeRange(0, 18-overshoot)];
        self->buf_i += 6; // This autoincrements on the meter
        [self callCB:@"sample_buf"];
        
    } else if( UUID_EQUALS(@"FFA6")) {
        NSLog(@"Read meter settings: %d", characteristic.value.length);
        [characteristic.value getBytes:&self->meter_settings length:characteristic.value.length];
        [self callCB:@"settings"];
        
    } else if( UUID_EQUALS(@"FFA7")) {
        NSLog(@"Read adc settings");
        [characteristic.value getBytes:&self->ADC_settings length:characteristic.value.length];
        [self callCB:@"adc_settings"];
        
    } else if( UUID_EQUALS(@"FFA8")) {
        NSLog(@"Read cal");
        [characteristic.value getBytes:((char*)(self->meter_cal) + self->cal_i) range:NSMakeRange(0, 18)];
        [self callCB:@"cal_point"];
        
    } else  {
        NSLog(@"We read something I don't recognize...");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic.UUID,error);
    
    if(        UUID_EQUALS(@"FFA5") ) {
        [self callCB:@"write_sample_buf_i"];
    } else if( UUID_EQUALS(@"FFA6") ) {
        [self callCB:@"write_settings"];
    } else if( UUID_EQUALS(@"FFA7")) {
        [self callCB:@"write_adc_settings"];
    } else if( UUID_EQUALS(@"FFA9")) {
        [self callCB:@"write_cal_i"];
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
            // TODO : This is a hack to skip the first 4 cals (factory cals).  They just take time right now.
            next+=4;
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
            [self downloadCalPoint:next-4 target:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 10:
            [self callCB:@"setup"];
            break;
        default:
            NSLog(@"in doSetup ended up somewhere impossible");
    }
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
    /* Figure out what our measurement mode is */
    unsigned char pga_gain = self->ADC_settings.str.ch1set >> 4;
    double c_gain = 1.0;
    double c_offset = 0.0;
    int24_test offset_cal;
    switch( self->ADC_settings.str.ch1set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            c_gain = (1/(5e-3)) * 2.42 / (1<<23);
            offset_cal = self->meter_cal[4].electrodes_gain0.ch1_offset;
            break;
        case 0x03:
            // Power supply measurement
            c_gain = 2*2.42/(1<<23);
            offset_cal = self->meter_cal[4].internal_short.ch1_offset;
            break;
        case 0x04:
            // Temperature sensor
            c_gain   = (1./490e-6)*2.42/(1<<23);
            c_offset = 270.918367;
            offset_cal = self->meter_cal[4].internal_short.ch1_offset;
            break;
        case 0x09:
            // Channel 3 in
            c_gain     = 2.42/(1<<23);
            offset_cal = self->meter_cal[4].electrodes_gain0.ch1_offset;
            break;
        default:
            NSLog(@"Unrecognized CH1SET setting");
    }
    if(offset)
        base -= (double)[self to_int32:offset_cal];
    base *= pga_gain;
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
                    // Re-interpret base as a resistance assuming 10k inline
                    base = ((-11e3*base) - (1e3*1.21)) / (1.21+base);
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
            return @"Current";
            break;
        case 0x03:
            // Power supply measurement
            return @"Battery Voltage";
            break;
        case 0x04:
            // Temperature sensor
            return @"Temperature";
            break;
        case 0x09:
            // Channel 3 in
            return @"CH3 Voltage";
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
    double base = (double)reading;
    /* Figure out what our measurement mode is */
    unsigned char pga_gain = self->ADC_settings.str.ch2set >> 4;
    double c_gain = 1.0;
    double c_offset = 0.0;
    int24_test offset_cal;
    switch( self->ADC_settings.str.ch2set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            if( self->ADC_settings.str.gpio & 0x02 ) {
                c_gain = ((2e6+1918.36)/(1918.36)) * 2.42 / (1<<23);
                offset_cal = self->meter_cal[4].electrodes_gain1.ch2_offset;
            } else {
                c_gain = ((2e6+47e3)/(47e3)) * 2.42 / (1<<23);
                offset_cal = self->meter_cal[4].electrodes_gain0.ch2_offset;
            }
            break;
        case 0x03:
            // Power supply measurement
            c_gain = 4*2.42/(1<<23);
            offset_cal = self->meter_cal[4].internal_short.ch2_offset;
            break;
        case 0x04:
            // Temperature sensor
            c_gain   = (1./490e-6)*2.42/(1<<23);
            c_offset = 270.918367;
            offset_cal = self->meter_cal[4].internal_short.ch2_offset;
            break;
        case 0x09:
            // Channel 3 in
            c_gain     = 2.42/(1<<23);
            offset_cal = self->meter_cal[4].electrodes_gain0.ch2_offset;
            break;
        default:
            NSLog(@"Unrecognized CH2SET setting");
    }
    if(offset)
        base -= (double)[self to_int32:offset_cal];
    base *= pga_gain;
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
                    // Re-interpret base as a resistance assuming 10k inline
                    base = ((-11e3*base) - (1e3*1.21)) / (1.21+base);
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
            return @"Voltage";
            break;
        case 0x03:
            // Power supply measurement
            return @"Battery Voltage";
            break;
        case 0x04:
            // Temperature sensor
            return @"Temperature";
            break;
        case 0x09:
            // Channel 3 in
            return @"CH3 Voltage";
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
