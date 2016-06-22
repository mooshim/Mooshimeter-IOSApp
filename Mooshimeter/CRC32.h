//
// Created by James Whong on 5/26/16.
// Copyright (c) 2016 mooshim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (CRC)

-(uint32_t) crc32;
-(uint32_t) crc32WithSeed:(uint32_t)seed;
-(uint32_t) crc32UsingPolynomial:(uint32_t)poly;
-(uint32_t) crc32WithSeed:(uint32_t)seed usingPolynomial:(uint32_t)poly;

@end