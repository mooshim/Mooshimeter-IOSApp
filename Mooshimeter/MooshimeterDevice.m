//#import "MooshimeterDevice.h"

#import "MooshimeterDeviceBase.h"
#import "LGBluetooth.h"
#import "BLEUtility.h"
#import "ConfigNode.h"
#import "NSMutableData+ByteBuffer.h"
#import "Prefman.h"
#import "TempUnitsHelper.h"
#import "MathInputDescriptor.h"
#import "GCD.h"

#import <Crashlytics/Answers.h>

////////////////////////////////
// MEMBERS FOR TRACKING AVAILABLE INPUTS AND RANGES
////////////////////////////////

@interface MyRangeDescriptor:RangeDescriptor
@property ConfigNode *node;
@end
@implementation MyRangeDescriptor
@end

@interface MyInputDescriptor:InputDescriptor
@property ConfigNode *input_node;
@property ConfigNode *analysis_node;
@property ConfigNode *shared_node;
@end
@implementation MyInputDescriptor
@end

@interface MooshimeterDevice()
@property LogFile* active_log;
@property NSMutableArray* logfiles;
@end

@implementation MooshimeterDevice{
    BOOL stop_heartbeat;
}
////////////////////////////////
// Private methods for dealing with config tree
////////////////////////////////
NSString* cleanFloatFmt(float d) {
    if (((float)((int) d)) == (d)) {
        return [NSString stringWithFormat:@"%d",(int)d];
    } else {
        return [NSString stringWithFormat:@"%f",d];
    }
}
NSString* toRangeLabel(float max){
    static NSString* prefixes[] = {@"n",@"?",@"m",@"",@"k",@"M",@"G"};
    int prefix_i = 3;
    while(max >= 1000.0) {
        max /= 1000;
        prefix_i++;
    }
    while(max < 1.0) {
        max *= 1000;
        prefix_i--;
    }
    return [cleanFloatFmt(max) stringByAppendingString:prefixes[prefix_i]];
}
void addRangeDescriptors(InputDescriptor* id, ConfigNode* rangenode) {
    for(ConfigNode *r in rangenode.children) {
        MyRangeDescriptor* rd = [[MyRangeDescriptor alloc]init];
        rd.node = r;
        rd.max  = [r.name floatValue];
        rd.name = [toRangeLabel(rd.max) stringByAppendingString:id.units];
        [id.ranges add:rd];
    }
}

////////////////////////////////
// METHODS
////////////////////////////////

-(instancetype) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    // We are expecting periph to already have had its services discovered
    self = [super init:periph delegate:delegate];

    stop_heartbeat = NO;

    self.logfiles = [[NSMutableArray alloc]init];
    self.tree = [[ConfigTree alloc]init];

    self->input_descriptors[CH1]  = [[Chooser alloc]init];
    self->input_descriptors[CH2]  = [[Chooser alloc]init];
    self->input_descriptors[MATH] = [[Chooser alloc]init];

    // Populate our characteristic array
    for(LGService * service in periph.services) {
        if ( [service.UUIDString isEqualToString:[BLEUtility expandToMooshimUUIDString:METER_SERVICE_UUID]] ) {
            [self populateLGDict:service.characteristics];
            break;
        }
    }

    if( [self getLGChar:METER_SERIN]==nil || [self getLGChar:METER_SEROUT]==nil) {
        NSLog(@"Problem discovering services");
        return nil;
    }

    [self.periph registerDisconnectHandler:^(NSError *error) {
        stop_heartbeat = YES;
        [self.delegate onDisconnect];
    }];

    [GCD asyncBack:^{
        [_tree attach:self];
        // At this point the tree is loaded.
        // July242016: Found a bug in CoreBluetooth that is causing the "service" member of cbCharacteristics
        // to be an object of the wrong type, causing a crash down the line.  It only comes up when logging
        // is being torture tested on the meter, which causes readings to be streamed out immediately to the
        // iOS device.  It only manifests the second time you connect to the meter after starting the app.
        // As a mitigation strategy, I'm going to immediately try to pause a meter after connecting
        [self pause];
        // Refresh all values in the tree.
        [_tree refreshAll];
        // Start a heartbeat.  The Mooshimeter needs to hear from the phone every 20 seconds or it
        // assumes the Android device has fallen in to a phantom connection mode and disconnects itself.
        // We will just read out the PCB version every 10 seconds to satisfy this constraint.
        [self heartbeatCB];
        [self setTime:[[NSDate date] timeIntervalSince1970]];
        [self addDescriptors];
        [self.delegate onInit];
    }];

    return self;
}
-(void)addDescriptors {
    Channel c = CH1;
    Chooser* l = input_descriptors[c];

    [l add:[self makeInputDescriptor:c name:@"CURRENT DC" node_name:@"CURRENT" analysis:@"MEAN" units:@"A" shared:false]];
    [l add:[self makeInputDescriptor:c name:@"CURRENT AC" node_name:@"CURRENT" analysis:@"RMS" units:@"A" shared:false]];
    [l add:[self makeInputDescriptor:c name:@"INTERNAL TEMPERATURE" node_name:@"TEMP" analysis:@"MEAN" units:@"K" shared:false]];
    // Create a hook for this input because thermocouple input will need to refer to it later
    MyInputDescriptor *auxv_id = [self makeInputDescriptor:c name:@"AUXILIARY VOLTAGE DC" node_name:@"AUX_V" analysis:@"MEAN" units:@"V" shared:YES];
    [l add:auxv_id];
    [l add:[self makeInputDescriptor:c name:@"AUXILIARY VOLTAGE AC" node_name:@"AUX_V" analysis:@"RMS" units:@"V" shared:YES]];
    [l add:[self makeInputDescriptor:c name:@"RESISTANCE" node_name:@"RESISTANCE" analysis:@"MEAN" units:@"\u03A9" shared:YES]];
    [l add:[self makeInputDescriptor:c name:@"DIODE DROP" node_name:@"DIODE" analysis:@"MEAN" units:@"V" shared:YES]];

    c = CH2;
    l = input_descriptors[c];

    [l add:[self makeInputDescriptor:c name:@"VOLTAGE DC" node_name:@"VOLTAGE" analysis:@"MEAN" units:@"V" shared:NO]];
    [l add:[self makeInputDescriptor:c name:@"VOLTAGE AC" node_name:@"VOLTAGE" analysis:@"RMS" units:@"V" shared:NO]];
    // Create a hook for this input because thermocouple input will need to refer to it later
    MyInputDescriptor *temp_id = [self makeInputDescriptor:c name:@"INTERNAL TEMPERATURE" node_name:@"TEMP" analysis:@"MEAN" units:@"K" shared:NO];
    [l add:temp_id];
    [l add:[self makeInputDescriptor:c name:@"AUXILIARY VOLTAGE DC" node_name:@"AUX_V" analysis:@"MEAN" units:@"V" shared:YES]];
    [l add:[self makeInputDescriptor:c name:@"AUXILIARY VOLTAGE AC" node_name:@"AUX_V" analysis:@"RMS" units:@"V" shared:YES]];
    [l add:[self makeInputDescriptor:c name:@"RESISTANCE" node_name:@"RESISTANCE" analysis:@"MEAN" units:@"\u03A9" shared:YES]];
    [l add:[self makeInputDescriptor:c name:@"DIODE DROP" node_name:@"DIODE" analysis:@"MEAN" units:@"V" shared:YES]];

    c = MATH;
    l = input_descriptors[c];

    DECLARE_WEAKSELF;
    MathInputDescriptor *mid = [[MathInputDescriptor alloc] initWithName:@"REAL POWER" units_arg:@"W"];
    mid.onChosen = ^(){};
    mid.meterSettingsAreValid = ^BOOL() {
        MyInputDescriptor * id0 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH1];
        MyInputDescriptor * id1 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH2];
        BOOL valid = YES;
        valid &= [id0.units isEqualToString:@"A"];
        valid &= [id1.units isEqualToString:@"V"];
        return valid;
    };
    mid.calculate = ^MeterReading *() {
        MeterReading* rval = [MeterReading mult:[ws getValue:CH1] m1:[ws getValue:CH2]];
        rval.value = [((NSNumber *) [ws.tree getValueAt:@"REAL_PWR"]) floatValue];
        return rval;
    };
    [l add:mid];

    mid = [[MathInputDescriptor alloc] initWithName:@"APPARENT POWER" units_arg:@"W"];
    mid.onChosen = ^(){};
    mid.meterSettingsAreValid = ^BOOL() {
        MyInputDescriptor * id0 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH1];
        MyInputDescriptor * id1 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH2];
        BOOL valid = YES;
        valid &= [id0.units isEqualToString:@"A"];
        valid &= [id1.units isEqualToString:@"V"];
        return valid;
    };
    mid.calculate = ^MeterReading *() {
        return [MeterReading mult:[ws getValue:CH1] m1:[ws getValue:CH2]];
    };
    [l add:mid];

    mid = [[MathInputDescriptor alloc] initWithName:@"POWER FACTOR" units_arg:@""];
    mid.onChosen = ^(){};
    mid.meterSettingsAreValid = ^BOOL() {
        MyInputDescriptor * id0 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH1];
        MyInputDescriptor * id1 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH2];
        BOOL valid = YES;
        valid &= [id0.units isEqualToString:@"A"]|| [id0.units isEqualToString:@"V"];
        valid &= [id1.units isEqualToString:@"V"];
        return valid;
    };
    mid.calculate = ^MeterReading *() {
        // We use MeterReading*.mult to ensure we get the decimals right
        MeterReading* rval = [MeterReading mult:[ws getValue:CH1] m1:[ws getValue:CH2]];
        // Then overload the value
        float real_power = [((NSNumber *) [ws.tree getValueAt:@"REAL_PWR"]) floatValue];
        rval.value = real_power/rval.value; //real power over apparent power
        rval.units = @"";
        return rval;
    };
    [l add:mid];

    mid = [[MathInputDescriptor alloc] initWithName:@"THERMOCOUPLE K" units_arg:@"C"];
    mid.onChosen = ^(){
        // Do we need to weakify these input descriptors?
        [ws setInput:CH1 descriptor:auxv_id];
        [ws setInput:CH2 descriptor:temp_id];
    };
    mid.meterSettingsAreValid = ^BOOL() {
        MyInputDescriptor *id0 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH1];
        MyInputDescriptor *id1 = (MyInputDescriptor*)[ws getSelectedDescriptor:CH2];
        BOOL valid = YES;
        valid &= id0 == auxv_id;
        valid &= id1 == temp_id;
        return valid;
    };
    mid.calculate = ^MeterReading *() {
        float volts = [ws getValue:CH1].value;
        float delta_c = [TempUnitsHelper KThermoVoltsToDegC:volts];
        float internal_temp = [ws getValue:CH2].value;
        MeterReading* rval;
        if([Prefman getPreference:PREF_USE_FAHRENHEIT def:NO]) {
            delta_c = [TempUnitsHelper relK2F:delta_c];
            rval = [[MeterReading alloc] initWithValue:internal_temp+delta_c
                                          n_digits_arg:5
                                               max_arg:2000
                                             units_arg:@"F"];
        } else {
            rval = [[MeterReading alloc] initWithValue:internal_temp+delta_c
                                          n_digits_arg:5
                                               max_arg:1000
                                             units_arg:@"C"];
        }
        return rval;
    };
    [l add:mid];

    // Stitch together updates on nodes of the config tree with calls to the delegate

    [self attachCallback:@"CH1:MAPPING" cb:^(NSObject *payload) {
        [ws determineInputDescriptorIndex:CH1];
        [ws.delegate onInputChange:CH1 descriptor:[ws getSelectedDescriptor:CH1]];
    }];
    [self attachCallback:@"CH1:ANALYSIS" cb:^(NSObject *payload) {
        [ws determineInputDescriptorIndex:CH1];
        [ws.delegate onInputChange:CH1 descriptor:[ws getSelectedDescriptor:CH1]];
    }];
    [self attachCallback:@"CH2:MAPPING" cb:^(NSObject *payload) {
        [ws determineInputDescriptorIndex:CH2];
        [ws.delegate onInputChange:CH2 descriptor:[ws getSelectedDescriptor:CH2]];
    }];
    [self attachCallback:@"CH2:ANALYSIS" cb:^(NSObject *payload) {
        [ws determineInputDescriptorIndex:CH2];
        [ws.delegate onInputChange:CH2 descriptor:[ws getSelectedDescriptor:CH2]];
    }];
    [self attachCallback:@"CH1:VALUE" cb:^(NSObject *payload) {
        MeterReading *val = [ws wrapMeterReading:CH1 val:[((NSNumber *) payload) floatValue]];
        [ws.delegate onSampleReceived:0 c:CH1 val:val];
    }];
    [self attachCallback:@"CH1:OFFSET" cb:^(NSObject *payload) {
        float offset = [((NSNumber *) payload) floatValue];
        [ws.delegate onOffsetChange:CH1 offset:[ws wrapMeterReading:CH1 val:offset]];
    }];
    [self attachCallback:@"CH2:VALUE" cb:^(NSObject *payload) {
        MeterReading *val = [ws wrapMeterReading:CH2 val:[((NSNumber *) payload) floatValue]];
        [ws.delegate onSampleReceived:0 c:CH2 val:val];
    }];
    [self attachCallback:@"CH2:OFFSET" cb:^(NSObject *payload) {
        float offset = [((NSNumber *) payload) floatValue];
        [ws.delegate onOffsetChange:CH2 offset:[ws wrapMeterReading:CH2 val:offset]];
    }];
    [self attachCallback:@"CH1:BUF" cb:^(NSObject *payload) {
        // payload is a byte[] which we must translate in to
        NSArray* samplebuf = [ws interpretSampleBuffer:CH1 payload:(NSData*)payload];
        float dt = (float)[self getSampleRateHz];
        dt = (float)1.0/dt;
        [ws.delegate onBufferReceived:[[NSDate date] timeIntervalSince1970] c:CH1 dt:dt val:samplebuf];
    }];
    [self attachCallback:@"CH2:BUF" cb:^(NSObject *payload) {
        // payload is a byte[] which we must translate in to
        NSArray* samplebuf = [ws interpretSampleBuffer:CH2 payload:(NSData*)payload];
        float dt = (float)[self getSampleRateHz];
        dt = (float)1.0/dt;
        [ws.delegate onBufferReceived:[[NSDate date] timeIntervalSince1970] c:CH2 dt:dt val:samplebuf];
    }];
    [self attachCallback:@"REAL_PWR" cb:^(NSObject *payload) {
        [ws.delegate onSampleReceived:[[NSDate date] timeIntervalSince1970]   c:MATH val:[ws getValue:MATH]];
    }];
    [self attachCallback:@"CH1:RANGE_I" cb:^(NSObject *payload) {
        int i = [((NSNumber *) payload) intValue];
        [ws.delegate onRangeChange:CH1 new_range:[[ws getSelectedDescriptor:CH1].ranges get:i]];
    }];
    [self attachCallback:@"CH2:RANGE_I" cb:^(NSObject *payload) {
        int i = [((NSNumber *) payload) intValue];
        [ws.delegate onRangeChange:CH2 new_range:[[ws getSelectedDescriptor:CH2].ranges get:i]];
    }];
    [self attachCallback:@"SAMPLING:RATE" cb:^(NSObject *payload) {
        [ws.delegate onSampleRateChanged:[ws getSampleRateHz]];
    }];
    [self attachCallback:@"SAMPLING:DEPTH" cb:^(NSObject *payload) {
        [ws.delegate onBufferDepthChanged:[ws getBufferDepth]];
    }];
    [self attachCallback:@"LOG:ON" cb:^(NSObject *payload) {
        int i = [((NSNumber *) payload) intValue];
        [ws.delegate onLoggingStatusChanged:(i!=0) new_state:[ws getLoggingStatus] message:[ws getLoggingStatusMessage]];
    }];
    [self attachCallback:@"LOG:STATUS" cb:^(NSObject *payload) {
        [ws.delegate onLoggingStatusChanged:[ws getLoggingOn] new_state:[ws getLoggingStatus] message:[ws getLoggingStatusMessage]];
    }];
    [self attachCallback:@"BAT_V" cb:^(NSObject *payload) {
        float bat_v = [((NSNumber *) payload) floatValue];
        [ws.delegate onBatteryVoltageReceived:bat_v];
    }];
    [self attachCallback:@"LOG:INFO:INDEX" cb:^(NSObject *payload) {
        ws.active_log = [[LogFile alloc]init];
        ws.active_log.index = [(NSNumber *) payload intValue];
        ws.active_log.meter = ws;
        [ws.logfiles insertObject:ws.active_log atIndex:ws.active_log.index];
    }];
    [self attachCallback:@"LOG:INFO:END_TIME" cb:^(NSObject *payload) {
        uint32_t utc_time = [(NSNumber*)payload unsignedIntValue];
        ws.active_log.end_time = utc_time;
    }];
    [self attachCallback:@"LOG:INFO:N_BYTES" cb:^(NSObject *payload) {
        uint32_t bytes = [(NSNumber*)payload unsignedIntValue];
        ws.active_log.bytes = bytes;
        [ws.delegate onLogInfoReceived:ws.active_log];
    }];
    [self attachCallback:@"LOG:STREAM:DATA" cb:^(NSObject *payload) {
        NSData* data = (NSData*)payload;
        [ws.active_log appendToFile:data];
        [ws.delegate onLogDataReceived:ws.active_log data:data];
        if(ws.active_log.bytes <= [ws.active_log getFileSize]){
            [ws.delegate onLogFileReceived:ws.active_log];
        }
    }];

    // Figure out which input we're presently reading based on the tree state
    if(![self determineInputDescriptorIndex:CH1]) {
        [self setInput:CH1 descriptor:[self getInputList:CH1][0]];
    }
    if(![self determineInputDescriptorIndex:CH2]) {
        [self setInput:CH2 descriptor:[self getInputList:CH2][0]];
    }

}
-(void)attachCallback:(NSString*)nodestr cb:(NotifyHandler)cb {
    ConfigNode *n = [self.tree getNode:nodestr];
    if(n==nil) {return;}
    [n addNotifyHandler:cb];
}
-(void)removeCallback:(NSString*)nodestr cb:(NotifyHandler)cb {
    ConfigNode *n = [self.tree getNode:nodestr];
    if(n==nil) {return;}
    [n removeNotifyHandler:cb];
}

////////////////////////////////
// Private helpers
////////////////////////////////

-(ConfigNode*) getInputNode:(Channel)c {
    NSMutableString* cmd = [NSMutableString string];
    switch(c) {
        case CH1:
            [cmd appendString:@"CH1"];
            break;
        case CH2:
            [cmd appendString:@"CH2"];
            break;
        default:
            NSLog(@"This is bad");
            break;
    }
    [cmd appendString:@":MAPPING"];
    ConfigNode* rval = [_tree getNode:cmd];
    while(true) {
        if (rval.ntype == NTYPE_LINK) {
            rval = [_tree getNode:(NSString*)rval.value];
        } else if(rval.ntype== NTYPE_CHOOSER) {
            rval = [rval getChosen];
        } else {
            return rval;
        }
    }
}
-(NSObject*)getValueAt:(NSString*)p {
    NSObject* rval = [_tree getValueAt:p];
    if(rval==nil) {
        // FIXME: hack
        return @0;
    }
    return rval;
}

-(NSNumber*) getNSNumberAt:(NSString*)p {
    NSObject* rval = [self getValueAt:p];
    if([rval isKindOfClass:[NSNumber class]]) {
        NSNumber* cast = (NSNumber*)rval;
        return cast;
    } else {
        NSLog(@"Invalid conversion");
        return @0;
    }
}

-(int)getIntAt:(NSString*)p {
    return [[self getNSNumberAt:p] intValue];
}

-(float)getFloatAt:(NSString*)p {
    return [[self getNSNumberAt:p] floatValue];
}

-(NSArray<NSString*>*) getChildNameList:(ConfigNode*)n {
    NSMutableArray<NSString*>* inputs = [@[] mutableCopy];
    for(ConfigNode* child in n.children) {
        [inputs addObject:child.name];
    }
    return inputs;
}
NSString* nameForChannel(Channel c) {
    switch(c) {
        case CH1:
            return @"CH1";
        case CH2:
            return @"CH2";
        default:
            NSLog(@"Bad Channel enum!");
            return nil;
    }
}
NSMutableString* concat(int n_strings,...) {
    va_list valist;
    NSMutableString* rval = [NSMutableString string];
    int i;
    va_start(valist, n_strings);
    for (i = 0; i < n_strings; i++) {
        [rval appendString:va_arg(valist,NSString*)];
    }
    va_end(valist);
    return rval;
}

-(MyInputDescriptor*)makeInputDescriptor:(Channel)c name:(NSString*)name node_name:(NSString*)node_name analysis:(NSString*)analysis units:(NSString*)units shared:(BOOL)shared {
    MyInputDescriptor *i = [[MyInputDescriptor alloc] init];
    NSString* analysis_node_name = concat(3,nameForChannel(c),@":ANALYSIS:",analysis);
    i.analysis_node = [_tree getNode:analysis_node_name];
    i.name          = name;
    i.units         = units;
    if(shared) {
        i.shared_node   = [_tree getNode:concat(2,nameForChannel(c),@":MAPPING:SHARED")];
        i.input_node    = [_tree getNode:concat(2,@"SHARED:",node_name)];
    } else {
        i.input_node    = [_tree getNode:concat(3,nameForChannel(c),@":MAPPING:",node_name)];
    }
    addRangeDescriptors(i,i.input_node);
    return i;
}
-(BOOL)determineInputDescriptorIndex:(Channel)c {
    //returns YES if descriptor found, NO otherwise
    if(c==MATH) {
        // Math input can be set arbitrarily
        return YES;
    }
    Chooser *chooser = input_descriptors[c];
    ConfigNode* selected_input_node = [self getInputNode:c];
    for(MyInputDescriptor *d in chooser.choices) {
        if(selected_input_node == d.input_node) {
            if(d.analysis_node == [[_tree getNode:concat(2,nameForChannel(c),@":ANALYSIS")] getChosen]) {
                [chooser chooseObject:d];
                return YES;
            }
        }
    }
    return NO;
}
-(NSArray<NSNumber*>*)interpretSampleBuffer:(Channel)c payload:(NSData*)payload {
    NSString* cname = nameForChannel(c);
    int bytes_per_sample = [((NSNumber *) [_tree getValueAt:concat(2, cname, @":BUF_BPS")]) intValue];
    bytes_per_sample /= 8;
    float lsb2native = [((NSNumber *) [_tree getValueAt:concat(2, cname, @":BUF_LSB2NATIVE")]) floatValue];
    int n_samples = payload.length/bytes_per_sample;
    NSMutableArray<NSNumber*>* rval = [NSMutableArray arrayWithCapacity:n_samples];
    NSMutableData* b = [payload mutableCopy];
    for(int i = 0; i < n_samples; i++) {
        int val=0;
        if(bytes_per_sample==3)      {val = [b popInt24];}
        else if(bytes_per_sample==2) {val = [b popShort];}
        else if(bytes_per_sample==1) {val = [b popInt8];}
        else{NSLog(@"Badness ensues");}
        [rval addObject:[NSNumber numberWithFloat:(((float)val)*lsb2native)]];
    }
    return rval;
}

-(MeterReading*)wrapMeterReading:(Channel)c val:(float)val {
    MyInputDescriptor *id = (MyInputDescriptor *)[self getSelectedDescriptor:c];
    float enob = [self getEnob:c];
    float max = [self getMaxRangeForChannel:c];
    MeterReading* rval;
    if([id.units isEqualToString:@"K"]) {
        // Nobody likes Kelvin!  C or F?
        if([Prefman getPreference:PREF_USE_FAHRENHEIT def:NO]) {
            rval = [[MeterReading alloc] initWithValue:[TempUnitsHelper absK2F:val]
                                          n_digits_arg:(int) log10(pow(2, enob))
                                               max_arg:[TempUnitsHelper absK2F:max]
                                             units_arg:@"F"];
        } else {
            rval = [[MeterReading alloc] initWithValue:[TempUnitsHelper absK2C:val]
                                          n_digits_arg:(int)log10(pow(2,enob))
                                               max_arg:[TempUnitsHelper absK2C:max]
                                             units_arg:@"C"];
        }
    } else {
        rval = [[MeterReading alloc] initWithValue:val
                                      n_digits_arg:(int)log10f(powf(2.0f,enob))
                                           max_arg:max
                                         units_arg:id.units];
    }
    return rval;
}

////////////////////////////////
// BLEDeviceBase methods
////////////////////////////////

-(void)heartbeatCB {
    if(stop_heartbeat || ![self isConnected]) {
        return;
    }
    [_tree command:@"PCB_VERSION"];
    [GCD asyncBackAfterMS:10000 block:^{
        [self heartbeatCB];
    }];
}

////////////////////////////////
// MooshimeterControlInterface methods
////////////////////////////////

-(void) pause {
    [_tree command:@"SAMPLING:TRIGGER 0"];
}
    
-(void) oneShot {
    [_tree command:@"SAMPLING:TRIGGER 1"];
}

-(void) stream {
    [_tree command:@"SAMPLING:TRIGGER 2"];
}

-(void) reboot {
    [_tree command:@"REBOOT 0"];
}

-(void) enterShippingMode {
    [_tree command:@"REBOOT 1"];
}
    
-(int) getPCBVersion {
    NSObject *o = [_tree getValueAt:@"PCB_VERSION"];
    if(o==nil) {
        return 8; // Default to 8 (RevI)
    }
    return [((NSNumber *) o) intValue];
}
    
-(double) getUTCTime {
    // WARNING: Meter only returns it as a uint32, so the double is always guaranteed to be rounded to the nearest second
    return [((NSNumber *) [_tree getValueAt:@"TIME_UTC"]) doubleValue];
}
    
-(void) setTime:(double)utc_time {
    NSString *cmd = [NSString stringWithFormat:@"TIME_UTC %u", (uint32_t)[[NSDate date] timeIntervalSince1970]];
    [_tree command:cmd];
}
    
-(MeterReading*)getOffset:(Channel)c {
    NSNumber* offset = (NSNumber*)[_tree getValueAt:concat(2,nameForChannel(c),@":OFFSET")];
    return [self wrapMeterReading:c val:[offset floatValue]];
}
    
-(void) setOffset:(Channel)c offset:(float)offset {
    NSNumber* nobj = [NSNumber numberWithFloat:offset];
    [_tree command:concat(3,nameForChannel(c),@":OFFSET ",[nobj stringValue])];
}
    
-(BOOL)bumpRange:(Channel)c expand:(BOOL)expand {
    ConfigNode* rnode = [self getInputNode:c];
    NSString* range_i_str = concat(2,nameForChannel(c),@":RANGE_I");
    int cnum = [((NSNumber *) [_tree getValueAt:range_i_str]) intValue];
    int n_choices = rnode.children.count;
    // If we're not wrapping and we're against a wall
    if (cnum == 0 && !expand) {
        return NO;
    }
    if(cnum == n_choices-1 && expand) {
        return NO;
    }
    cnum += expand?1:-1;
    cnum %= n_choices;
    [_tree command:concat(2,range_i_str, [NSString stringWithFormat:@" %u",cnum])];
    return YES;
}
-(float)getMinRangeForChannel:(Channel)c {
    ConfigNode* rnode = [self getInputNode:c];
    NSString* range_i_str = concat(2,nameForChannel(c),@":RANGE_I");
    NSUInteger cnum = [((NSNumber *) [_tree getValueAt:range_i_str]) unsignedIntegerValue];
    cnum = cnum>0?cnum-1:cnum;
    ConfigNode* choice = rnode.children[cnum];
    return (float)0.9* [choice.name floatValue];
}
-(float)getMaxRangeForChannel:(Channel)c {
    ConfigNode* rnode = [self getInputNode:c];
    NSString* range_i_str = concat(2,nameForChannel(c),@":RANGE_I");
    NSUInteger cnum = [((NSNumber *) [_tree getValueAt:range_i_str]) unsignedIntegerValue];
    ConfigNode* choice = rnode.children[cnum];
    return (float)1.1* [choice.name floatValue];
}
-(BOOL) applyAutorange:(Channel)c {
    if(![self getAutorangeOn:c]) {
        return NO;
    }
    float max = [self getMaxRangeForChannel:c];
    float min = [self getMinRangeForChannel:c];
    float val = [self getValue:c].value + [self getOffset:c].value;
    val = fabs(val);
    if(val > max) {
        return [self bumpRange:c expand:YES];
    }
    if(val < min) {
        return [self bumpRange:c expand:NO];
    }
    return NO;
}
    
-(BOOL)applyAutorange {
    BOOL rval = NO;
    rval |= [self applyAutorange:CH1];
    rval |= [self applyAutorange:CH2];
    BOOL rms_on = NO;
    rms_on |= [[[_tree getNode:@"CH1:ANALYSIS"] getChosen].name isEqualToString:@"RMS"];
    rms_on |= [[[_tree getNode:@"CH2:ANALYSIS"] getChosen].name isEqualToString:@"RMS"];
    if(self.rate_auto) {
        if( rms_on ) {
            if(![[[_tree getNode:@"SAMPLING:RATE"] getChosen].name isEqualToString:@"4000"]) {
                [_tree command:@"SAMPLING:RATE 5"];
            }
        } else {
            if(![[[_tree getNode:@"SAMPLING:RATE"] getChosen].name isEqualToString:@"125"]) {
                [_tree command:@"SAMPLING:RATE 0"];
            }
        }
    }
    if(self.depth_auto) {
        if( rms_on ) {
            if(![[[_tree getNode:@"SAMPLING:DEPTH"] getChosen].name isEqualToString:@"256"]) {
                [_tree command:@"SAMPLING:DEPTH 3"];
            }
        } else {
            if(![[[_tree getNode:@"SAMPLING:DEPTH"] getChosen].name isEqualToString:@"32"]) {
                [_tree command:@"SAMPLING:DEPTH 0"];
            }
        }
    }
    return rval;
}

    
-(void) setName:(NSString*)name {
    [_tree command:concat(2,@"NAME ",name)];
}

    
-(NSString*)getName {
    NSString* rval = (NSString*)[_tree getValueAt:@"NAME"];
    // Strip out any trailing nulls.  Why is this so annoying?
    uint8_t buffer[[rval length]];
    NSUInteger written=0;
    [rval getBytes:buffer maxLength:[rval length] usedLength:&written encoding:NSASCIIStringEncoding options:nil range:NSMakeRange(0,[rval length]) remainingRange:nil];
    //Find a null
    NSUInteger i = 0;
    for(i=0; i < written; i++) {
        if(buffer[i]==0x00) {break;}
    }
    return [rval substringToIndex:i];
}

-(float) getEnob:(Channel)c {
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
    int samplerate_setting = [self getSampleRateIndex];
    double buffer_depth_log4 = log([self getBufferDepth])/log(4);
    double enob = base_enob_table[ samplerate_setting ];
    // Oversampling adds 1 ENOB per factor of 4
    enob += (buffer_depth_log4);

    if(     [self getPCBVersion]==7
            && c == CH1
            && ((MyInputDescriptor*)[self getSelectedDescriptor:CH1]).input_node == [_tree getNode:@"CH1:MAPPING:CURRENT"] ) {
        // This is compensation for a bug in RevH, where current sense chopper noise dominates
        enob -= 2;
    }
    return enob;
}
-(NSString*) getUnits:(Channel)c {
    return [self getSelectedDescriptor:c].units;
}

-(NSString*) getInputLabel:(Channel)c {
    return [self getSelectedDescriptor:c].name;
}
-(int) getSampleRateIndex {
    return [[self getNSNumberAt:@"SAMPLING:RATE"] intValue];
}
    
-(int) getSampleRateHz {
    NSString* dstring = [_tree getChosenName:@"SAMPLING:RATE"];
    return [dstring intValue];
}
    
-(int)setSampleRateIndex:(int)i {
    NSString* cmd = [NSString stringWithFormat:@"SAMPLING:RATE %d",i];
    [_tree command:cmd];
    return 0;
}

-(NSArray<NSString*>*) getSampleRateList {
    return [self getChildNameList:[_tree getNode:@"SAMPLING:RATE"]];
}
    
-(int)getBufferDepth {
    NSString *dstring = [_tree getChosenName:@"SAMPLING:DEPTH"];
    return [dstring intValue];
}
    
-(int)setBufferDepthIndex:(int)i {
    NSString *cmd = [NSString stringWithFormat:@"SAMPLING:DEPTH %d",i];
    [_tree command:cmd];
    return 0;
}
    
-(NSArray<NSString*>*)getBufferDepthList {
    return [self getChildNameList:[_tree getNode:@"SAMPLING:DEPTH"]];
}

    
-(void) setBufferMode:(Channel)c on:(BOOL)on {
    static int preBufferModeStash[] = {0,0};// FIXME: make this an ivar
    NSString *cmd = concat(2,nameForChannel(c),@":ANALYSIS");
    if(on) {
        preBufferModeStash[c] = [[self getNSNumberAt:cmd] intValue];
        if(preBufferModeStash[c]==2){ // We were already in buffer mode!  Error recovery
            preBufferModeStash[c]=0;
        }
        cmd = concat(2,cmd,@" 2"); // cmd += " 2";
    } else {
        cmd = [NSString stringWithFormat:@"%@ %d",cmd,preBufferModeStash[c]];
    }
    [_tree command:cmd];
}
    
-(BOOL)getLoggingOn {
    int i = [[self getNSNumberAt:@"LOG:ON"] intValue];
    return i!=0;
}
    
-(void) setLoggingOn:(BOOL)on {
    int i=on?1:0;
    NSString *cmd = [NSString stringWithFormat:@"LOG:ON %d",i];
    [_tree command:cmd];
}
    
-(NSString*)getLoggingStatusMessage {
    const NSString* messages[] = {
            @"OK",
            @"No SD card detected",
            @"SD card failed to mount - check filesystem",
            @"SD card is full",
            @"SD card write error",
            @"END_OF_FILE",
    };
    return [messages[[self getLoggingStatus]] copy];
}
    
-(void)setLoggingInterval:(int)ms {
    int interval_s = ms/1000;
    NSString* cmd = [NSString stringWithFormat:@"LOG:INTERVAL %d", interval_s];
    [_tree command:cmd];
}
    
-(int) getLoggingIntervalMS {
    int s = [[self getNSNumberAt:@"LOG:INTERVAL"] intValue];
    return 1000*s;
}
    
-(MeterReading*) getValue:(Channel)c {
    NSString* path;
    MathInputDescriptor * id;
    switch(c) {
        case CH1:
        case CH2:
            path = [NSString stringWithFormat:@"%@%@",nameForChannel(c),@":VALUE"];
            return [self wrapMeterReading:c val:[[self getNSNumberAt:path] floatValue]];
        case MATH:
            id = [input_descriptors[MATH] getChosen];
            if([id meterSettingsAreValid]) {
                return id.calculate();
            } else {
                return [[MeterReading alloc] initWithValue:0 n_digits_arg:0 max_arg:0 units_arg:@"INVALID INPUTS"];
            }
    }
    // Should never reach here!
    return [[MeterReading alloc] initWithValue:0 n_digits_arg:0 max_arg:0 units_arg:@"INVALID"];;
}
    
-(int) getLoggingStatus {
    return [[self getNSNumberAt:@"LOG:STATUS"] intValue];
}
    
-(NSString*) getRangeLabel:(Channel)c {
    MyInputDescriptor * id = (MyInputDescriptor *)[self getSelectedDescriptor:c];
    int range_i = [[self getNSNumberAt:concat(2, nameForChannel(c), @":RANGE_I")] intValue];
    // FIXME: This is borking because our internal descriptor structures are out of sync with the configtree updates
    RangeDescriptor *rd =[id.ranges get:range_i];
    if(rd!=nil) {
        return rd.name;
    }
    // Log the circumstance of this failure!

    [Answers logCustomEventWithName:@"getRangeLabelCrash"
                   customAttributes:@{
                           @"StackTrace":[NSThread callStackSymbols],
                           @"InputDescriptor":[NSString stringWithFormat:@"%@",id],
                           @"TreeEnumeration":[self.tree enumerate]
                   }];
    return @"";
}

-(NSArray<RangeDescriptor*>*)getRangeList:(Channel)c {
    return [[self getSelectedDescriptor:c].ranges.choices copy];
}

-(NSArray<NSString*>*)getRangeNameList:(Channel)c {
    NSMutableArray <NSString*>* rval = [NSMutableArray array];
    for(MyRangeDescriptor* rd in [self getSelectedDescriptor:c].ranges.choices) {
        [rval addObject:rd.name];
    }
    return rval;
}

-(int)setRange:(Channel)c rd:(RangeDescriptor*)rd {
    InputDescriptor * id = [self getSelectedDescriptor:c];
    [id.ranges chooseObject:rd];
    NSString* cmd = [NSString stringWithFormat:@"%@:RANGE_I %d",nameForChannel(c),id.ranges.chosen_i];
    [_tree command:cmd];
    return 0;
}
    
-(int) setInput:(Channel)c descriptor:(InputDescriptor*)descriptor {
    Chooser* chooser = input_descriptors[c];
    MyInputDescriptor * cast = (MyInputDescriptor *)descriptor;
    switch(c) {
        case CH1:
        case CH2:
            if(cast.shared_node!=nil) {
                // Make sure we're not about to jump on to a channel that's in use
                Channel other = c==CH1?CH2:CH1;
                MyInputDescriptor *other_id = [input_descriptors[other] getChosen];
                if(other_id.shared_node!=nil) {
                    NSLog(@"Tried to select an input already in use!");
                    return -1;
                }
            }

            [chooser chooseObject:cast];
            // Reset range manually... probably a cleaner way to do this
            [[_tree getNode:concat(2, nameForChannel(c), @":RANGE_I")] setValue:@0];

            [cast.input_node choose];
            if(cast.shared_node!=nil) {
                [cast.shared_node choose];
            }
            [cast.analysis_node choose];
            break;
        case MATH:
            ((MathInputDescriptor*)descriptor).onChosen();
            [chooser chooseObject:descriptor];
            [self.delegate onInputChange:c descriptor:descriptor];
            break;
    }
    return 0;
}
    
-(NSArray*) getInputList:(Channel)c {
    // Returns the inputs available for the channel
    if(c==MATH) {
        return input_descriptors[c].choices;
    }
    Channel other = c==CH1?CH2:CH1;
    MyInputDescriptor * other_id = (MyInputDescriptor *)[self getSelectedDescriptor:other];
    if(other_id.shared_node==nil) {
        // Other channel is not using shared input
        return input_descriptors[c].choices;
    }
    // If we're here, we need to filter the return value
    NSMutableArray * rval = [@[] mutableCopy];
    for(MyInputDescriptor * my_id in input_descriptors[c].choices) {
        if(my_id.shared_node==nil) {
            [rval addObject:my_id];
        }
    }
    return rval;
}

-(NSArray*)getInputNameList:(Channel)c {
    NSMutableArray <NSString*>* rval = [NSMutableArray array];
    for(MyInputDescriptor * i in [self getInputList:c]) {
        [rval addObject:i.name];
    }
    return rval;
}
    
-(InputDescriptor*) getSelectedDescriptor:(Channel)c {
    return [input_descriptors[c] getChosen];
}

-(RangeDescriptor*) getSelectedRange:(Channel)c {
    NSString* range_i_str = concat(2,nameForChannel(c),@":RANGE_I");
    NSUInteger cnum = [((NSNumber *) [_tree getValueAt:range_i_str]) unsignedIntegerValue];
    return [self getSelectedDescriptor:c].ranges.choices[cnum];
}

-(void)pollLogInfo {
    [self.tree command:@"LOG:POLLDIR 1"];
}
-(void)downloadLog:(LogFile*)log {
    self.active_log = log;
    uint32_t filesize = [log getFileSize];
    if(filesize>=log.bytes) {
        // Already downloaded the whole file
        [GCD asyncBack:^{
            [self.delegate onLogFileReceived:log];
        }];
    } else {
        if(filesize>0) {
            [self setLogOffset:filesize];
        }
        [self.tree command:[NSString stringWithFormat:@"LOG:STREAM:INDEX %d",log.index]];
    }
}
-(void)cancelLogDownload {
    [self.tree command:@"LOG:STREAM:INDEX -1"];
}
-(LogFile*) getLogInfo:(int)index {
    return self.logfiles[index];
}
-(void) setLogOffset:(uint32_t)offset {
    [self.tree command:[NSString stringWithFormat:@"LOG:STREAM:OFFSET %u",offset]];
}
@end