
SECTION code_user

include "macros.inc"

PUBLIC _sound_interrupt_handler
PUBLIC _sample_pointer
PUBLIC _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

EXTERN sound_loader_read_buffer

defc BUFFER_SIZE_BITS = 11 ; 
defc BUFFER_SIZE = 2 ** BUFFER_SIZE_BITS
defc BUFFER_H_MASK = (BUFFER_SIZE - 1) >> 8
defc BUFFER_H_OVERFLOW_BIT = BUFFER_SIZE_BITS - 8
defc DOUBLE_BUFFER_H_OVERFLOW_BIT = BUFFER_H_OVERFLOW_BIT + 1
defc SAMPLES_BUFFER = 0x50C000

; TODO: add to general library in z88dk
defc REG_DAC_LEFT = 0x2C
defc REG_DAC_MONO = 0x2D
defc REG_DAC_RIGHT = 0x2E  

; Exported symbols
defc _SOUND_SAMPLES_BUFFER_SIZE = BUFFER_SIZE
defc _SOUND_SAMPLES_BUFFER = SAMPLES_BUFFER

_sound_interrupt_handler:
    push af
    push bc
    push hl

    ; Saves the current page in MMU 6
    READ_NEXTREG(REG_MMU6)
    push af

    ld a, _SOUND_SAMPLES_BUFFER >> 16
    nextreg REG_MMU6, a
    ld hl, (_sample_pointer)
    ld a, (hl)
    nextreg REG_DAC_LEFT, a
    inc hl
    ld a, (hl)
    nextreg REG_DAC_RIGHT, a
    inc hl
    ld a, l
    and a
    jr nz, no_end_of_buffer
    ld a, h
    and BUFFER_H_MASK
    jr nz, no_end_of_buffer
    res DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (_sample_pointer), hl
    push ix
    push de
    ld ix, _SOUND_SAMPLES_BUFFER
    bit BUFFER_H_OVERFLOW_BIT, h    ; If this bit is set, the first buffer has been consumed
    jr nz, read_buffer
    ld ix, _SOUND_SAMPLES_BUFFER + _SOUND_SAMPLES_BUFFER_SIZE
read_buffer:
    call sound_loader_read_buffer
    pop de
    pop ix
    jr end_interrupt

no_end_of_buffer:
    ld (_sample_pointer), hl
    ; Restores the currengt page in MMU 6
end_interrupt:
    pop af
    nextreg REG_MMU6, a
    pop hl
    pop bc
    pop af
    ei
    reti
; ---------------------------------------------------------------    

SECTION data_user

_sample_pointer:
    defw SAMPLES_BUFFER & 0xFFFF
_end_sample_pointer:
    defw (SAMPLES_BUFFER + 2 * BUFFER_SIZE) & 0xFFFF
