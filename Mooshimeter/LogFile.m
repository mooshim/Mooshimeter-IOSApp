//
// Created by James Whong on 10/7/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "LogFile.h"
#import "MooshimeterDeviceBase.h"
#import "GCD.h"

const NSString* logdir_name = @"MooshimeterLogs";

@interface LogFile()
@property (strong,atomic) NSFileHandle * file_handle;
@end

@implementation LogFile {
    NSString* file_path;
}

-(instancetype)init {
    self = [super init];
    [[NSFileManager defaultManager] setDelegate:self];
    return self;
}

-(NSString*)getFileName {
    if(file_path==nil) {
        [GCD syncMain:^{
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            file_path = paths[0];
            file_path = [file_path stringByAppendingPathComponent:logdir_name];
            NSFileManager* man = [NSFileManager defaultManager];
            if(![man fileExistsAtPath:file_path isDirectory:nil]) {
                if(![man createDirectoryAtPath:file_path withIntermediateDirectories:YES attributes:nil error:nil]) {
                    NSLog(@"Failed to create dir");
                    NSLog(@"Error was code: %d - message: %s", errno, strerror(errno));
                }
            }
            NSMutableString* filename = [NSMutableString string];
            NSDate* end_time = [NSDate dateWithTimeIntervalSince1970:_end_time];
            NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"yyyyMMdd_HHmm"];
            [filename appendString:[_meter getName]];
            [filename appendString:@"-Log"];
            [filename appendFormat:@"%u", _index];
            [filename appendString:@"-"];
            [filename appendString:[formatter stringFromDate:end_time]];
            [filename appendString:@".csv"];
            file_path = [file_path stringByAppendingPathComponent:filename];
        }];
    }
    return file_path;
}

-(void)deleteFile {
    NSString* path = [self getFileName];
    if(self.file_handle!=nil) {
        NSLog(@"Closing open file handle");
        [self.file_handle closeFile];
        self.file_handle = nil;
    }
    if([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"Deleting %@",path);
        NSError* error;
        if(![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            NSLog(@"Failed to remove file!");
            if(error!=nil) {
                NSLog(@"Error:%d :%@",error.code,error.description);
            }
        }
    }
}

-(NSFileHandle*)getFile {
    [GCD syncMain:^{
        if(self.file_handle == nil) {
            NSString* path = [self getFileName];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                // Create the file
                if(![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]) {
                    NSLog(@"Error was code: %d - message: %s", errno, strerror(errno));
                }
            }
            self.file_handle = [NSFileHandle fileHandleForWritingAtPath:path];
            [self.file_handle seekToEndOfFile];
        }
    }];
    return self.file_handle;
}

- (void)appendToFile:(NSData *)payload {
    [GCD syncMain:^{
        NSLog(@"Appending %u bytes", payload.length);
        NSFileHandle * handle = [self getFile];
        [handle writeData:payload];
        [handle synchronizeFile];
    }];
}

-(uint32_t)getFileSize {
    __block uint64_t rval;
    NSFileHandle * handle = [self getFile];
    [GCD syncMain:^{
        rval = handle.offsetInFile;
    }];
    NSLog(@"From %@: %u: Filesize %llu",[NSThread currentThread].description, [NSThread currentThread].hash, rval);
    return (uint32_t)rval;
}

@end