#ifndef _INT24_H_
#define _INT24_H_

typedef union {
  struct {
    signed short low;
    signed char high;
  } str;
  struct {
    signed char low;
    signed short high;
  } str2;
  unsigned char bytes[3];
} int24_test;

extern inline int24_test from_int32(signed long);
extern inline signed long to_int32( int24_test );

extern inline float to_float( int24_test );

extern inline signed short top_short( int24_test );

typedef union {
  signed long as_int32;
  struct {
    int24_test low;
    char high;
  } as_int24;
} int24_int32_union;

#pragma inline=forced
inline int24_test from_int32(signed long arg)
{
  return ((int24_int32_union*)&arg)->as_int24.low;
}

#pragma inline=forced
inline signed long to_int32( int24_test arg )
{
  int24_int32_union retval;
  retval.as_int24.low = arg;
  retval.as_int24.high = retval.as_int24.low.str.high&0x80?0xFF:0x00;
  return retval.as_int32;
}

#pragma inline=forced
inline float to_float( int24_test arg )
{
  float retval = 0;
  char* p = (char*)(&retval);
  p[0] = arg.bytes[0];
  p[1] = arg.bytes[1];
  p[2] = arg.bytes[2] | 0x80;
  p[3] = 0x3F;
  if( arg.bytes[2] & 0x80 ) {
    // TODO: off by one on sign flipping, but don't want to do an extended add.
    p[0]  = ~p[0];
    p[1]  = ~p[1];
    p[2] ^= 0x7F;
    p[3] |= 0x80;
  }
  return retval;
}

#define top_short(arg) ((arg).str2.high)
#define bottom_short(arg) ((arg).str.low)

#endif