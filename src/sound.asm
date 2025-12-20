
SECTION code_user

include "macros.inc"

PUBLIC _sound_interrupt_handler
PUBLIC _sample_pointer
PUBLIC _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

EXTERN lsound_loader_read_buffer

defc _SOUND_SAMPLES_BUFFER_SIZE = 2048
; C000 Buffer 1
; C800 Buffer 2
; D000 End of buffers

; Bit for buffer 1 = 3
; Bit for buffer 2 = 4

defc _SOUND_SAMPLES_BUFFER = 0x50C000

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
    res 4, h
    ld (_sample_pointer), hl
    bit 3, h
    push ix
    jr z, buffer1_empty
    ; Buffer 0 empty
    ld ix, _SOUND_SAMPLES_BUFFER
    call lsound_loader_read_buffer
    pop ix
    jr end_interrupt
buffer1_empty:
    ; Buffer 1 empty
    ld ix, _SOUND_SAMPLES_BUFFER + _SOUND_SAMPLES_BUFFER_SIZE
    call lsound_loader_read_buffer
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
    defw _SOUND_SAMPLES_BUFFER & 0xFFFF


