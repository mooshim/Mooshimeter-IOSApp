//
// Created by James Whong on 5/9/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "oad.h"

@interface FirmwareImageDownloader : NSObject

@property NSData *imageData;
@property (assign) img_hdr_t imageHeader;
@property bool download_complete;

+(instancetype)initSingleton;
+(instancetype)getSharedInstance;
+(bool)isFirmwareDownloadComplete;
+(img_hdr_t)getFirmwareImageHeader;
+(NSData*)getFirmwareImageData;

+(uint32)getBuildTime;
@end