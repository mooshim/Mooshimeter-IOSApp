//
// Created by James Whong on 5/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "FirmwareImageDownloader.h"
#import "GCD.h"

@implementation FirmwareImageDownloader

static FirmwareImageDownloader *shared = nil;

+(instancetype)initSingleton {
    // Call me once
    if(shared==nil) {
        shared = [[FirmwareImageDownloader alloc]init];
    }
    return shared;
}

+ (instancetype)getSharedInstance {
    return shared;
}


+(bool)isFirmwareDownloadComplete {
    return shared.download_complete;
}
+(img_hdr_t)getFirmwareImageHeader {
    return shared.imageHeader;
}
+(NSData*)getFirmwareImageData {
    return shared.imageData;
}

+(uint32)getBuildTime {
    return shared.imageHeader.build_time;
}

-(instancetype)init {
    // clear
    self.imageData = nil;
    self.download_complete=NO;

    // start background download
    NSString *stringURL = @"https://moosh.im/s/f/mooshimeter-firmware-latest.bin";
    //NSString *stringURL = @"https://moosh.im/s/f/mooshimeter-firmware-beta.bin";
    NSURL  *url = [NSURL URLWithString:stringURL];
    [GCD asyncBack:^{
        img_hdr_t tmp_header = {0};
        self.imageData = [NSData dataWithContentsOfURL:url];
        NSLog(@"Loaded firmware of size : %d",(int)self.imageData.length);
        if(self.imageData.length==0) {
            // We failed to load the firmware.  Should we do something?
            NSLog(@"Firmware download failed!");
        } else {
            [self.imageData getBytes:&tmp_header length:sizeof(img_hdr_t)];
            self.imageHeader = tmp_header;
            self.download_complete = YES;
        }
    }];
    return self;
}

@end