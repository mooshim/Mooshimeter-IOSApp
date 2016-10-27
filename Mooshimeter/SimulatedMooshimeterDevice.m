#import "SimulatedMooshimeterDevice.h"

#import "GCD.h"

@implementation SimulatedMooshimeterDevice{
    BOOL connected;
    BOOL streaming;
    BOOL logging;
    int logging_interval;
    NSString* name;
    MeterReading * offsets[2];
}

-(MeterReading*)genFakeReading {
    return [[MeterReading alloc] initWithValue:(float)(10*sin([self getUTCTime]))
                           n_digits_arg:4
                                max_arg:100
                              units_arg:@"FAKE"];
}

////////////////////////////////
// METHODS
////////////////////////////////

-(instancetype) init:(LGPeripheral*)periph delegate:(id<MooshimeterDelegateProtocol>)delegate {
    // We are expecting periph to already have had its services discovered
    self = [super init:periph delegate:delegate];

    connected = NO;
    streaming = NO;
    logging = NO;
    logging_interval = 10000;
    name = @"Simulated";

    offsets[0] = [[MeterReading alloc] initWithValue:0
                                                n_digits_arg:4
                                                     max_arg:100
                                                   units_arg:@"FAKE"];
    offsets[1] = [[MeterReading alloc] initWithValue:0
                                        n_digits_arg:4
                                             max_arg:100
                                           units_arg:@"FAKE"];

    return self;
}

////////////////////////////////
// MooshimeterControlInterface methods
////////////////////////////////

-(int)initialize{}
-(void)reboot{
    [GCD asyncBackAfterMS:1000 block:^{
        connected = NO;
        [self.delegate onDisconnect];
    }];
}

////////////////////////////////
// Convenience functions
////////////////////////////////

-(BOOL)isInOADMode {
    return NO;
}

//////////////////////////////////////
// Autoranging
//////////////////////////////////////

//-(BOOL)bumpRange:(Channel)c expand:(BOOL)expand;

// Return true if settings changed
//-(BOOL)applyAutorange;

//////////////////////////////////////
// Interacting with the Mooshimeter itself
//////////////////////////////////////

-(void)setName:(NSString*)name_arg{name=name_arg;}
-(NSString*)getName {return name;}

-(void)runStreamer {
    [GCD asyncBack:^{
        double time = [self getUTCTime];
        [self.delegate onSampleReceived:time c:CH1 val:[self genFakeReading]];
        [self.delegate onSampleReceived:time c:CH2 val:[self genFakeReading]];
    }];
    if(streaming) {
        [GCD asyncBackAfterMS:250 block:^{
            [self runStreamer];
        }];
    }
}

-(void)pause {
    streaming = NO;
}
-(void)oneShot {
    streaming = NO;
}
-(void)stream {
    streaming = YES;
}
-(BOOL)isStreaming {
    return streaming;
}

-(void)enterShippingMode {
    [self reboot];
}

-(int)getPCBVersion {
    return 8;
}

-(double)getUTCTime {
    return [[NSDate date] timeIntervalSince1970];
}
-(void)setTime:(double) utc_time {}

-(MeterReading*) getOffset:(Channel)c {
    return offsets[c];
}
-(void)setOffset:(Channel)c offset:(float)offset {
    offsets[c].value=offset;
}

-(int)getSampleRateHz{return 125;}
-(int) getSampleRateIndex{return 0;}
-(int)setSampleRateIndex:(int)i{}
-(NSArray<NSString*>*) getSampleRateList{return @[@"125"];}

-(int)getBufferDepth{return 256;}
-(int)setBufferDepthIndex:(int)i{return 0;}
-(NSArray<NSString*>*) getBufferDepthList{return @[@"256"];}

-(void)setBufferMode:(Channel)c on:(BOOL)on{}

-(BOOL)getLoggingOn {return logging;}
-(void)setLoggingOn:(BOOL)on{logging=on;}
-(int)getLoggingStatus{return 0;}
-(NSString*)getLoggingStatusMessage{return @"OK";}
-(void)setLoggingInterval:(int)ms {logging_interval = ms;}
-(int)getLoggingIntervalMS {return logging_interval;}

-(MeterReading*) getValue:(Channel)c {
    return [self genFakeReading];
}

-(NSString*)   getRangeLabel:(Channel)c {
    return @"100";
}
-(int)         setRange:(Channel)c rd:(RangeDescriptor*)rd {}
-(NSArray<RangeDescriptor*>*)getRangeList:(Channel)c {
    RangeDescriptor * rval = [[RangeDescriptor alloc]init];
    rval.name = @"100F";
    rval.max = 100;
    return @[rval];
}
-(NSArray<NSString*>*)getRangeNameList:(Channel)c {
    return @[@"100"];
}

-(NSString*) getInputLabel:(Channel)c {
    return [NSString stringWithFormat:@"Fake %d", c];
}
-(int)setInput:(Channel)c descriptor:(InputDescriptor*)descriptor {}
-(NSArray*)getInputList:(Channel)c {
    return @[[[InputDescriptor alloc] initWithName:@"Fake" units_arg:@"F"]];
}
-(NSArray*)getInputNameList:(Channel)c {return @[@"Fake Input"];}
-(InputDescriptor*) getSelectedDescriptor:(Channel)c {
    return [[InputDescriptor alloc] initWithName:@"Fake" units_arg:@"F"];
}
-(RangeDescriptor*) getSelectedRange:(Channel)c {
    RangeDescriptor * rval = [[RangeDescriptor alloc]init];
    rval.max = 100;
    rval.name = @"100";
    return rval;
}

@end