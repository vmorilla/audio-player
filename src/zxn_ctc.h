#ifndef _ZXN_CTC_H_
#define _ZXN_CTC_H_

#define __IO_CTC0 0x183B // CTC channel 0 port
#define __IO_CTC1 0x193B // CTC channel 1 port
#define __IO_CTC2 0x1A3B // CTC channel 2 port
#define __IO_CTC3 0x1B3B // CTC channel 3 port

#ifdef __CLANG

extern unsigned char IO_CTC0;
extern unsigned char IO_CTC1;
extern unsigned char IO_CTC2;
extern unsigned char IO_CTC3;

#else

__sfr __banked __at __IO_CTC0 IO_CTC0;
__sfr __banked __at __IO_CTC1 IO_CTC1;
__sfr __banked __at __IO_CTC2 IO_CTC2;
__sfr __banked __at __IO_CTC3 IO_CTC3;

#endif

#endif