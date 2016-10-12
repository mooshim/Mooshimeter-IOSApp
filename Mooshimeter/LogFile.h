//
// Created by James Whong on 10/7/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MooshimeterDeviceBase;

@interface LogFile : NSObject
@property MooshimeterDeviceBase* meter;
@property int32_t index;
@property uint32_t bytes;
@property uint32_t end_time;

-(NSString*)getFilePath;
-(NSString*)getFileName;
-(void)appendToFile:(NSData*)payload;
-(NSFileHandle *)getFile;
-(uint32_t)getFileSize;
-(void)deleteFile;
@end