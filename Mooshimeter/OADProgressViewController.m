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

@implementation OADViewController
- (instancetype)initWithMeter:(MooshimeterDeviceBase*)meter
{
    self = [super init];
    // Initialization code
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
    self.async_block = ^{
        int rval = [ws upload_task];
        if(rval!=0) {
            ws.async_block = nil;
        }
    };
    [GCD asyncBack:self.async_block];
}

extern void discoverRecursively(NSArray* services,uint32 i, LGPeripheralDiscoverServicesCallback aCallback);

-(int)upload_task {
    // Assume we're on a background thread
    Lock* l = [[Lock alloc] init];
    if(![self.meter isInOADMode]) {
        [self toTerminal:@"Rebooting meter...\n"];
        [self.meter.periph registerDisconnectHandler:^(NSError *error) {
            [l signal];
        }];
        [self.meter reboot];
        [self toTerminal:@"Waiting for meter to disconnect...\n"];
        [l wait:6000];
        if([self.meter isConnected]) {
            [self toTerminal:@"Meter failed to disconnect!\n"];
            return -1;
        }
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
                                     [l signal];}];
            [l wait:2000];
            for (LGPeripheral *p in c.peripherals) {
                if([p.UUIDString isEqualToString:self.meter.periph.UUIDString]) {
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
            [l signal];
        }];
        if ([l wait:5000]) {
            [self toTerminal:@"Connection failed!\n"];
            return-1;
        }
        [self toTerminal:@"Connected.  Discovering services...\n"];
        [peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
            [l signal];
        }];
        if ([l wait:5000]) {
            [self toTerminal:@"Discovery failed!\n"];
            return -1;
        }
        if (peripheral.services.count == 0) {
            return -1;
        }
        discoverRecursively(peripheral.services, 0, ^(NSArray *characteristics, NSError *error) {
            [l signal];
        });
        if ([l wait:5000]) {
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
@end
