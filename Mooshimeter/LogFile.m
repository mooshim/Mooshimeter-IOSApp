//
// Created by James Whong on 10/7/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "LogFile.h"
#import "MooshimeterDeviceBase.h"

const NSString* logdir_name = @"MooshimeterLogs";

@interface LogFile()
@property (strong,atomic) NSFileHandle * file_handle;
@end

@implementation LogFile {
    NSString* file_path;
}

-(instancetype)init {
    self = [super init];
    return self;
}

-(NSString*)getFileName {
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
    return filename;
}

-(NSString*)getFilePath {
    if(file_path==nil) {
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
        NSMutableString* filename = [self getFileName];
        file_path = [file_path stringByAppendingPathComponent:filename];
    }
    return file_path;
}

-(void)deleteFile {
    NSString* path = [self getFilePath];
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
    if(self.file_handle == nil) {
        NSString* path = [self getFilePath];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            // Create the file
            if(![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]) {
                NSLog(@"Error was code: %d - message: %s", errno, strerror(errno));
            }
        }
        self.file_handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [self.file_handle seekToEndOfFile];
    }
    return self.file_handle;
}

- (void)appendToFile:(NSData *)payload {
    NSFileHandle * handle = [self getFile];
    [handle writeData:payload];
    [handle synchronizeFile];
}

-(uint32_t)getFileSize {
    uint64_t rval;
    NSFileHandle * handle = [self getFile];
    rval = handle.offsetInFile;
    return (uint32_t)rval;
}

@end