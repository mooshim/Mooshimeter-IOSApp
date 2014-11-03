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
    BUILD_BUG_ON(sizeof(trigger_settings_t)!=6);
    BUILD_BUG_ON(sizeof(MeterSettings_t)!=13);
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
    [BLEUtility readCharacteristic:self.p cUUID:METER_INFO];
}

-(void)reqMeterSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"settings" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p cUUID:METER_SETTINGS];
}

-(void)sendMeterSettings:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"write_settings" target:target cb:cb arg:arg];
    [BLEUtility writeCharacteristic:self.p cUUID:METER_SETTINGS data:[NSData dataWithBytes:(char*)(&self->meter_settings) length:sizeof(self->meter_settings)]];
}

-(void)reqMeterSample:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample" target:target cb:cb arg:arg];
    [BLEUtility readCharacteristic:self.p cUUID:METER_SAMPLE];
}

-(void)startStreamMeterSample:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample" target:target cb:cb arg:arg oneshot:NO];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_SAMPLE enable:YES];
}

-(void)stopStreamMeterSample {
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_SAMPLE enable:NO];
}

-(void)setBufferReceivedCallback:(id)target cb:(SEL)cb arg:(id)arg {
        [self createCB:@"sample_buf_downloaded" target:target cb:cb arg:arg oneshot:NO];
}

-(void)enableStreamMeterBuf:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"buf_stream" target:target cb:cb arg:arg];
    self->buf_i = 0;
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_CH1BUF enable:YES];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_CH2BUF enable:YES];
}

-(void)disableStreamMeterBuf {
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_CH1BUF enable:NO];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_CH2BUF enable:NO];
}

-(void)enableADCSettingsNotify:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"adc_settings_stream" target:target cb:cb arg:arg];
    [BLEUtility setNotificationForCharacteristic:self.p cUUID:METER_SETTINGS enable:YES];
}

-(void)setMeterLVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg {
    if(on) {
        self->meter_settings.rw.adc_settings |=  0x10;
    } else {
        self->meter_settings.rw.adc_settings &= ~0x10;
    }
    [self sendMeterSettings:target cb:cb arg:arg];
}

-(void)setMeterHVMode:(bool)on target:(id)target cb:(SEL)cb arg:(id)arg {
    if(on) {
        self->meter_settings.rw.adc_settings |=  0x20;
    } else {
        self->meter_settings.rw.adc_settings &= ~0x20;
    }
    [self sendMeterSettings:target cb:cb arg:arg];
}

-(void)downloadSampleBuffer:(id)target cb:(SEL)cb arg:(id)arg {
    [self createCB:@"sample_buf_downloaded" target:target cb:cb arg:arg];
    self->buf_i = 0;
    self->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_ONESHOT;
    [self sendMeterSettings:target cb:cb arg:arg];
}

-(void)setMeterState:(int)new_state target:(id)target cb:(SEL)cb arg:(id)arg{
    self->meter_settings.rw.target_meter_state = new_state;
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
    if( [service.UUID isEqual:[BLEUtility expandToMooshimUUID:METER_SERVICE_UUID]] ) {
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
    
    if( UUID_EQUALS(METER_SAMPLE)) {
        [self callCB:@"sample"];
    } else if( UUID_EQUALS(METER_CH1BUF)) {
        [self callCB:@"buf_stream"];
    } else if( UUID_EQUALS(METER_CH2BUF)) {
        [self callCB:@"buf_stream"];
    } else  {
        NSLog(@"We read something I don't recognize...");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    NSLog(@"didUpdateValueForCharacteristic = %@",characteristic.UUID);
    
    // Nasty hack to get around buffer sync
    static char last_received = 0;
    
    unsigned char buf[characteristic.value.length];
    [characteristic.value getBytes:&buf length:characteristic.value.length];
    
    if(        UUID_EQUALS(METER_INFO) ) {
        NSLog(@"Received Meter Info: %lu", (unsigned long)characteristic.value.length);
        [characteristic.value getBytes:&self->meter_info length:characteristic.value.length];
        [self callCB:@"info"];
        
    } else if( UUID_EQUALS(METER_SAMPLE)) {
        NSLog(@"Read sample");
        [characteristic.value getBytes:&self->meter_sample length:characteristic.value.length];
        [self callCB:@"sample"];
        
    } else if( UUID_EQUALS(METER_CH1BUF)) {
        if( last_received) self->buf_i = 0;
        last_received = 0;
        NSLog(@"Read ch1 buf: %d", self->buf_i);
        uint8 tmp[20];
        uint16 channel_buf_len_bytes = [self getBufLen]*sizeof(int24_test);
        [characteristic.value getBytes:tmp range:NSMakeRange(0, characteristic.value.length)];
        for(int i=0; i < characteristic.value.length; i++) {
            ((uint8*)(self->sample_buf.CH1_buf))[buf_i] = tmp[i];
            self->buf_i++;
        }
        if(self->buf_i >= channel_buf_len_bytes) {
            // We downloaded the whole CH1 sample buffer
            // Now expect CH2
            // TODO: This won't always be the case
            self->buf_i = 0;
        }
    } else if( UUID_EQUALS(METER_CH2BUF)) {
        if(!last_received) self->buf_i = 0;
        last_received = 1;
        NSLog(@"Read ch2 buf: %d", self->buf_i);
        uint8 tmp[20];
        uint16 channel_buf_len_bytes = [self getBufLen]*sizeof(int24_test);
        [characteristic.value getBytes:tmp range:NSMakeRange(0, characteristic.value.length)];
        for(int i=0; i < characteristic.value.length; i++) {
            ((uint8*)(self->sample_buf.CH2_buf))[buf_i] = tmp[i];
            self->buf_i++;
        }
        if(self->buf_i >= channel_buf_len_bytes) {
            // We downloaded the whole sample buffer
            [self callCB:@"sample_buf_downloaded"];
        }
    } else if( UUID_EQUALS(METER_SETTINGS)) {
        NSLog(@"Read meter settings: %lu", (unsigned long)characteristic.value.length);
        [characteristic.value getBytes:&self->meter_settings length:characteristic.value.length];
        [self callCB:@"settings"];
        
    } else  {
        NSLog(@"We read something I don't recognize...");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic.UUID,error);
    
    if( UUID_EQUALS(METER_SETTINGS) ) {
        [self callCB:@"write_settings"];
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
            // Enable notifications for the sample buffer (necessary to stream)
            [self enableStreamMeterBuf:self cb:@selector(doSetup:) arg:[NSNumber numberWithInt:next]];
            break;
        case 3:
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
           [self sendMeterSettings:self cb:@selector(restoreSettings:) arg:[NSNumber numberWithInt:next]];
           break;
       case 1:
           [self callCB:@"reconnect"];
           break;
       default:
           NSLog(@"in restore ended up somewhere impossible");
   }
}

-(int)getBufLen {
    return (1<<(self->meter_settings.rw.calc_settings & METER_CALC_SETTINGS_DEPTH_LOG2));
}

-(int)getBufMin:(int24_test*)buf {
    int i, tmp;
    int min = [self to_int32:buf[0]];
    for( i=0; i < [self getBufLen];  i++ ) {
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
    for( i=0; i < [self getBufLen];  i++ ) {
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

-(int)getBufAvg:(int24_test*)buf {
    int i;
    int avg = 0;
    for( i=0; i < [self getBufLen];  i++ ) {
        avg += [self to_int32:buf[i]];
    }
    avg /= [self getBufLen];
    return avg;
}

-(double)getCH1BufAvg {
    return [self calibrateCH1Value:[self getBufAvg:self->sample_buf.CH1_buf] offset:YES];
}
-(double)getCH2BufAvg {
    return [self calibrateCH2Value:[self getBufAvg:self->sample_buf.CH2_buf] offset:YES];
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
    double pga_gain = pga_lookup[self->meter_settings.rw.ch1set >> 4];
    double c_gain = 1.0;
    double c_offset = 0.0;
    switch( self->meter_settings.rw.ch1set & 0x0F ) {
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
    switch( self->meter_settings.rw.ch1set & 0x0F ) {
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

-(NSString*)getCH1Label {
    switch( self->meter_settings.rw.ch1set & 0x0F ) {
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
    switch( self->meter_settings.rw.ch1set & 0x0F ) {
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
    double pga_gain = pga_lookup[self->meter_settings.rw.ch2set >> 4];
    double c_gain = 1.0;
    double c_offset = 0.0;
    
    switch( self->meter_settings.rw.ch2set & 0x0F ) {
        case 0x00:
            // Regular electrode input
            switch( (self->meter_settings.rw.adc_settings>>4) & 0x03 ) {
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
    switch( self->meter_settings.rw.ch2set & 0x0F ) {
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


-(NSString*)getCH2Label {
    switch( self->meter_settings.rw.ch2set & 0x0F ) {
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
    switch( self->meter_settings.rw.ch2set & 0x0F ) {
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
