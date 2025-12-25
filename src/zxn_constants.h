#ifndef _ZXN_CONSTANTS_H_
#define _ZXN_CONSTANTS_H_

// Missing ZXN constants in Z88DK

#define REG_INTERRUPT_CONTROL 0xC0

#define REG_INTERRUPT_ENABLE_0 0xC4
#define REG_INTERRUPT_ENABLE_1 0xC5
#define REG_INTERRUPT_ENABLE_2 0xC6

#define REG_INTERRUPT_STATUS_0 0xC8
#define REG_INTERRUPT_STATUS_1 0xC9
#define REG_INTERRUPT_STATUS_2 0xCA

#define REG_DMA_INTERRUPT_ENABLE_0 0xCC
#define REG_DMA_INTERRUPT_ENABLE_1 0xCD
#define REG_DMA_INTERRUPT_ENABLE_2 0xCE

#define REG_DAC_LEFT 0x2C
#define REG_DAC_MONO 0x2D
#define REG_DAC_RIGHT 0x2E

#define CTC0 0x183B // CTC channel 0 port
#define CTC1 0x193B // CTC channel 1 port
#define CTC2 0x1A3B // CTC channel 2 port
#define CTC3 0x1B3B // CTC channel 3 port

#define IO_DAC_L0 0x0f
#define IO_DAC_L1 0x1f
#define IO_DAC_R0 0x4f
#define IO_DAC_R1 0x5f
#define IO_DAC_M0 0xdf

#define INTERRUPT_STATUS_CTC $C9

#define REG_MMU6 0x56

#define AY_REG 0xFFFD  // AY register select port
#define AY_DATA 0xBFFD // AY register data port

#define AY_TONE_A_LO 0x00 // R0 fine tune A
#define AY_TONE_A_HI 0x01 // R1 coarse tune A
#define AY_TONE_B_LO 0x02 // R2 fine tune B
#define AY_TONE_B_HI 0x03 // R3 coarse tune B
#define AY_TONE_C_LO 0x04 // R4 fine tune C
#define AY_TONE_C_HI 0x05 // R5 coarse tune C
#define AY_NOISE 0x06     // R6 noise period
#define AY_MIXER 0x07     // R7 mixer register
#define AY_VOLUME_A 0x08  // R8 volume A
#define AY_VOLUME_B 0x09  // R9 volume B
#define AY_VOLUME_C 0x0A  // R10 volume C
#define AY_ENV_LO 0x0B    // R11 envelope low
#define AY_ENV_HI 0x0C    // R12 envelope high
#define AY_ENV_SHAPE 0x0D // R13 envelope shape

#define TURBO_SOUND_CTRL 0xFFFD // Turbo sound control port
#define TURBO_SOUND_DATA 0xBFFD // Turbo sound data port
#define AY1_ACTIVE_CHIP 0b11    // AY1 active chip
#define AY2_ACTIVE_CHIP 0b10    // AY2 active chip
#define AY3_ACTIVE_CHIP 0b01    // AY3 active chip

#endif //_ZXN_CONSTANTS_H_