//
// Created by James Whong on 6/2/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import "NSMutableData+ByteBuffer.h"

@implementation NSMutableData(ByteBuffer)
-(NSData*)pop:(int)n_bytes {
    NSRange r = NSMakeRange(0,n_bytes);
    NSData* rval = [self subdataWithRange:r];
    [self replaceBytesInRange:r withBytes:nil length:0]; // This forces removal of bytes from front of array
    return rval;
}
-(uint8_t)popUint8 {
    NSData *bdata = [self pop:1];
    return ((uint8_t*)(bdata.bytes))[0];
}
-(int8_t)popInt8 {
    NSData *bdata = [self pop:1];
    return ((int8_t*)(bdata.bytes))[0];
}
-(int16_t)popShort {
    NSData *bdata = [self pop:2];
    return ((int16_t*)(bdata.bytes))[0];
}
-(int32_t)popInt24 {
    NSData *bdata = [self pop:3];
    int32_t rval = 0;
    // Copy
    memcpy(&rval,bdata.bytes,3);
    // Sign extend
    rval |= rval&0x00800000?0xFF000000:0x00000000;
    return rval;
}
-(int32_t)popInt {
    NSData *bdata = [self pop:4];
    return ((int32_t*)(bdata.bytes))[0];
}
-(float)popFloat {
    NSData *bdata = [self pop:4];
    return ((float*)(bdata.bytes))[0];
}
@end