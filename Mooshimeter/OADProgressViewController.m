//
//  OADViewController.m
//  TI BLE Multitool
//
//  Created by Ole Andreas Torvmark on 7/16/13.
//  Copyright (c) 2013 Ole Andreas Torvmark. All rights reserved.
//

#import "OADProgressViewController.h"
#import "Lock.h"
#import "FirmwareImageDownloader.h"
#import "GCD.h"

@implementation OADViewController {
    Lock* lock;
}
- (instancetype)initWithMeter:(MooshimeterDeviceBase*)meter
{
    self = [super init];
    lock = [[Lock alloc] init];
    self.meter = (OADDevice*)meter;
    return self;
}

-(void) setupView {
    float center = self.view.bounds.size.width / 2;
    float width = self.view.bounds.size.width - 40;
    
    self.percent_label.frame = CGRectMake(center - (width / 2), 20, width, 20);
    self.timing_label.frame = CGRectMake(center - (width / 2), 50, width, 20);
    self.progressBar.frame = CGRectMake(center - (width /2), 90, width, 20);
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.nrow = 8;
    self.ncol = 1;

    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];

    self.percent_label = [[UILabel alloc]init];
    self.timing_label  = [[UILabel alloc]init];
    self.percent_label.textAlignment = NSTextAlignmentCenter;
    self.timing_label.textAlignment  = NSTextAlignmentCenter;
    self.percent_label.textColor = [UIColor blackColor];
    self.timing_label.textColor  = [UIColor blackColor];
    self.percent_label.backgroundColor = [UIColor clearColor];
    self.timing_label.backgroundColor  = [UIColor clearColor];
    self.percent_label.font = [UIFont boldSystemFontOfSize:14.0f];
    self.timing_label.font  = [UIFont boldSystemFontOfSize:14.0f];

    [self setupView];

    [self.content_view addSubview:self.progressBar];
    [self.content_view addSubview:self.percent_label];
    [self.content_view addSubview:self.timing_label];

    self.title = @"Firmware Uploader";
    self.percent_label.text = @"0%";
    [self.view setNeedsLayout];

    self.terminal = [[UITextView alloc]init];
    self.terminal.font  = [UIFont systemFontOfSize:14.0f];
    self.terminal.editable = NO;
    self.terminal.frame = [self makeRectInGrid:0 row_off:2 width:1 height:5];

    [self.content_view addSubview:self.terminal];

    self.upload_button = [self makeButton:[self makeRectInGrid:0 row_off:7 width:1 height:1] cb:@selector(upload)];
    [self.upload_button setTitle:@"Start Upload" forState:UIControlStateNormal];
}

-(void)viewWillAppear:(BOOL)animated {
    [self.meter addDelegate:self];
    NSString* intro = [NSString stringWithFormat:@"Connected to: %@\nFirmware on meter: %d\nNew firmware: %d\n", [self.meter getName],[self.meter getBuildTime], [FirmwareImageDownloader getBuildTime]];
    [self toTerminal:intro];
}

-(void)toTerminal:(NSString*)s {
    [GCD asyncMain:^{
        [self.terminal setText:[self.terminal.text stringByAppendingString:s]];
        [self.terminal scrollRangeToVisible:NSMakeRange(self.terminal.text.length - 1, 1)];
    }];
}

-(void)upload {
    if(self.async_block!=nil) {
        [self toTerminal:@"Already uploading!\n"];
        return;
    }
    DECLARE_WEAKSELF;
    [GCD asyncMain:^{[self.upload_button setTitle:@"Uploading..." forState:UIControlStateNormal];}];
    self.async_block = ^{
        [ws upload_task];
        ws.async_block = nil;
        [GCD asyncMain:^{[ws.upload_button setTitle:@"Start Upload" forState:UIControlStateNormal];}];
    };
    [GCD asyncBack:self.async_block];
}

extern void discoverRecursively(NSArray* services,uint32 i, LGPeripheralDiscoverServicesCallback aCallback);

-(int)upload_task {
    // Assume we're on a background thread
    if(![self.meter isInOADMode]) {
        [self toTerminal:@"Rebooting meter...\n"];
        [self.meter reboot];
        [self toTerminal:@"Waiting for meter to disconnect...\n"];
        [lock wait:10000]; // onDisconnect will signal the lock
        if([self.meter isConnected]) {
            [self toTerminal:@"Meter failed to disconnect!\n"];
            return -1;
        }
        // Sleep for a while to allow disconnect handlers to trickle through.
        [NSThread sleepForTimeInterval:1.0];
        LGPeripheral* target_peripheral = self.meter.periph;
        self.meter = nil;
        [self toTerminal:@"Scanning for meter in bootloader mode."];
        NSArray *services_to_scan_for = @[[BLEUtility expandToMooshimUUID:OAD_SERVICE_UUID]];
        LGCentralManager *c = [LGCentralManager sharedInstance];
        LGPeripheral* peripheral = nil;
        for (int i = 0; i < 10 && peripheral==nil; i++) {
            [self toTerminal:@"."];
            [c scanForPeripheralsByInterval:1
                                   services:services_to_scan_for
                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
                                 completion:^(NSArray *peripherals) {
                                     NSLog(@"SCANSIG");
                                     [lock signal];}];
            [lock wait:2000];
            for (LGPeripheral *p in c.peripherals) {
                if([p.UUIDString isEqualToString:target_peripheral.UUIDString]) {
                    NSLog(@"FOUND");
                    peripheral = p;
                    break;
                }
            }
        }
        [self toTerminal:@"\n"];

        if (peripheral!=nil) {
            [self toTerminal:@"Found the meter in bootloader mode!  Connecting...\n"];
        } else {
            [self toTerminal:@"Could not find the meter!\n"];
            return -1;
        }
        [peripheral connectWithCompletion:^(NSError *error) {
            [lock signal];
        }];
        if ([lock wait:5000]) {
            [self toTerminal:@"Connection failed!\n"];
            return-1;
        }
        [self toTerminal:@"Connected.  Discovering services...\n"];
        [peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
            [lock signal];
        }];
        if ([lock wait:5000]) {
            [self toTerminal:@"Discovery failed!\n"];
            return -1;
        }
        if (peripheral.services.count == 0) {
            return -1;
        }
        discoverRecursively(peripheral.services, 0, ^(NSArray *characteristics, NSError *error) {
            [lock signal];
        });
        if ([lock wait:5000]) {
            [self toTerminal:@"Discovery failed!\n"];
            return -1;
        }
        [self toTerminal:@"Discovery successful!\n"];
        self.meter = [[OADDevice alloc] init:peripheral delegate:nil];
    }
    // Set up the OAD profile and link to self
    self.oad_profile = [[OADProfile alloc] init:self.meter];
    self.oad_profile.progressView = self;
    [self toTerminal:@"Uploading...\n"];
    [self.oad_profile startUpload];
    return 0;
}

- (void)onInit {}
- (void)onDisconnect {
    [lock signal];
}
- (void)onRssiReceived:(int)rssi {}
- (void)onBatteryVoltageReceived:(float)voltage {}
- (void)onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading *)val {}
- (void)onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber *> *)val {}
- (void)onSampleRateChanged:(int)sample_rate_hz {}
- (void)onBufferDepthChanged:(int)buffer_depth {}
- (void)onLoggingStatusChanged:(BOOL)on new_state:(int)new_state message:(NSString *)message {}
- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {}
- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {}
- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {}
@end
