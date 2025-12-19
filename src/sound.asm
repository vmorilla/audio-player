
SECTION code_user

include "macros.inc"

PUBLIC _sound_interrupt_handler
PUBLIC _sample_pointer, _empty_buffers_mask
PUBLIC _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

defc _SOUND_SAMPLES_BUFFER_SIZE = 2048
; C000 Buffer 1
; C800 Buffer 2
; D000 End of buffers

; Bit for buffer 1 = 3
; Bit for buffer 2 = 4

defc _SOUND_SAMPLES_BUFFER = 0x50C000

_sound_interrupt_handler:
    ;NEXTREG INTERRUPT_STATUS_CTC, 1
    push af
    ld a, (_empty_buffers_mask)
    cp 0x18 ; Bits 3 and 4 set -> no buffer to play
    jr nz, play_sample
    pop af
    ei
    reti
play_sample:
    push bc
    push hl

    ; Saves the current page in MMU 6
    READ_NEXTREG(REG_MMU6)
    push af

    ld a, _SOUND_SAMPLES_BUFFER >> 16
    nextreg REG_MMU6, a

    ld hl, (_sample_pointer)
    ld a, (hl)
    ld bc, IO_DAC_L0
    out (c), a
    inc hl
    ld a, (hl)
    set 6, c    ; IO_DAC_L0  + 0x40 = IO_DAC_R0
    out (c), a
    inc hl
    ld a, l
    and a
    jr nz, no_end_of_buffer
    ld a, h
    and 0x07
    jr nz, no_end_of_buffer
    ld a, (_empty_buffers_mask)
    or h 
    and 0x18 ; set bits 3 or 4 depending on which buffer ended   
    ld (_empty_buffers_mask), a
    cp 0x18
    jr nz, todo_bien
    xor a ; all buffers empty, should not happen
todo_bien:
    res 4, h
no_end_of_buffer:
    ld (_sample_pointer), hl
    ; Restores the currengt page in MMU 6
    pop af
    nextreg REG_MMU6, a
    pop hl
    pop bc
    pop af
    NEXTREG INTERRUPT_STATUS_CTC, 1
    ei
    reti
; ---------------------------------------------------------------    

SECTION data_user

_sample_pointer:
    defw _SOUND_SAMPLES_BUFFER & 0xFFFF
_empty_buffers_mask:
    defb 0x18 ; bit 0: buffer 0 empty, bit 1: buffer 1 empty

