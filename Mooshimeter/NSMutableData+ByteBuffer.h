//
// Created by James Whong on 6/2/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableData (ByteBuffer)
-(NSData*)pop:(int)n_bytes;
-(uint8_t)popUint8;
-(int8_t)popInt8;
-(int16_t)popShort;
-(int32_t)popInt24;
-(int32_t)popInt;
-(float)popFloat;
@end