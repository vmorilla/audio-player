include "config_zxn_private.inc"

; Reads a next register in A
#define READ_NEXTREG(REG) \
    push bc : \
    ld a, REG :\
    ld bc, __IO_NEXTREG_REG :\
    out (c), a :\
    inc b :\
    in a, (c) :\
    pop bc

#define SET_TURBO_SOUND_CTRL(N) \
    ld bc, TURBO_SOUND_CTRL : \
    ld a, N : \
    out (c), a

defc REG_INTERRUPT_CONTROL = 0xC0

defc REG_INTERRUPT_ENABLE_0 = 0xC4
defc REG_INTERRUPT_ENABLE_1 = 0xC5
defc REG_INTERRUPT_ENABLE_2 = 0xC6

defc REG_INTERRUPT_STATUS_0 = 0xC8
defc REG_INTERRUPT_STATUS_1 = 0xC9
defc REG_INTERRUPT_STATUS_2 = 0xCA

defc REG_DMA_INTERRUPT_ENABLE_0 = 0xCC
defc REG_DMA_INTERRUPT_ENABLE_1 = 0xCD
defc REG_DMA_INTERRUPT_ENABLE_2 = 0xCE

defc CTC0 = 0x183B ; CTC channel 0 port
defc CTC1 = 0x193B ; CTC channel 1 port
defc CTC2 = 0x1A3B ; CTC channel 2 port
defc CTC3 = 0x1B3B ; CTC channel 3 port

defc IO_DAC_L0 = 0x0f
defc IO_DAC_L1 = 0x1f
defc IO_DAC_R0 = 0x4f
defc IO_DAC_R1 = 0x5f
defc IO_DAC_M0 = 0xdf

defc INTERRUPT_STATUS_CTC = $C9

defc REG_MMU6 = 0x56

defc AY_REG = 0xFFFD ;   // AY register select port
defc AY_DATA = 0xBFFD ; // AY register data port

defc AY_TONE_A_LO = 0x00 ; // R0 fine tune A
defc AY_TONE_A_HI = 0x01 ; // R1 coarse tune A
defc AY_TONE_B_LO = 0x02 ; // R2 fine tune B
defc AY_TONE_B_HI = 0x03 ; // R3 coarse tune B
defc AY_TONE_C_LO = 0x04 ; // R4 fine tune C
defc AY_TONE_C_HI = 0x05 ; // R5 coarse tune C
defc AY_NOISE = 0x06 ; // R6 noise period
defc AY_MIXER = 0x07 ; // R7 mixer register
defc AY_VOLUME_A = 0x08 ; // R8 volume A
defc AY_VOLUME_B = 0x09 ; // R9 volume B
defc AY_VOLUME_C = 0x0A ; // R10 volume C
defc AY_ENV_LO = 0x0B ; // R11 envelope low
defc AY_ENV_HI = 0x0C ; // R12 envelope high
defc AY_ENV_SHAPE = 0x0D ; // R13 envelope shape

defc MMU_0 = __REG_MMU0
defc MMU_1 = __REG_MMU1
defc MMU_2 = __REG_MMU2
defc MMU_3 = __REG_MMU3
defc MMU_4 = __REG_MMU4
defc MMU_5 = __REG_MMU5
defc MMU_6 = __REG_MMU6
defc MMU_7 = __REG_MMU7

defc TURBO_SOUND_CTRL = 0xFFFD ; Turbo sound control port
defc TURBO_SOUND_DATA = 0xBFFD ; Turbo sound data port
defc AY1_ACTIVE_CHIP = 0b11 ; AY1 active chip
defc AY2_ACTIVE_CHIP = 0b10 ; AY2 active chip
defc AY3_ACTIVE_CHIP = 0b01 ; AY3 active chip