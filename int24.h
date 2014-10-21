#ifndef _INT24_H_
#define _INT24_H_

typedef union {
  struct {
    signed short low;
    signed char high;
  } str;
  unsigned char bytes[3];
} int24_test;

extern inline int24_test from_int32(signed long);
extern inline signed long to_int32( int24_test );

extern inline float to_float( int24_test );

extern inline signed short top_short( int24_test );

#pragma inline=forced
inline int24_test from_int32(signed long arg)
{
  /* Just discard the high byte */
  int24_test retval;
  char* a = (char*)(&arg);
  retval.bytes[0] = a[0];
  retval.bytes[1] = a[1];
  retval.bytes[2] = a[2];
  return retval;
}

#pragma inline=forced
inline signed long to_int32( int24_test arg )
{
  signed long retval;
  char* p = (char*)(&retval);
  p[0] = arg.bytes[0];
  p[1] = arg.bytes[1];
  p[2] = arg.bytes[2];
  
  /* sign extend */
  if( retval & 0x00800000 ) p[3] = 0xFF;
  else                      p[3] = 0x00;
  return retval;
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

#pragma inline=forced
inline signed short top_short( int24_test arg )
{
  signed short retval;
  char* p = (char*)(&retval);
  p[0] = arg.bytes[1];
  p[1] = arg.bytes[2];
  return retval;
}

#define bottom_short(arg) ((arg).str.low)

#endif