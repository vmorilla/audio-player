
SECTION code_user

INCLUDE "config_zxn_private.inc"
INCLUDE "zxn_constants.h"

PUBLIC sound_interrupt_handler
PUBLIC stereo_samples_channel, mono_samples_channel
PUBLIC STEREO_BUFFER_SIZE, MONO_BUFFER_SIZE
PUBLIC SC_CURSOR, SC_REMAINING_BUFFERS, SOUND_EOF_MARKER

EXTERN set_mmu_data_page_di, restore_mmu_data_page_di

defc STERO_BUFFER_SIZE_BITS = 10 ; 11 bits -> 2048 bytes stereo buffer, 10 bits -> 1024 bytes stereo buffer
defc STEREO_BUFFER_SIZE = 2 ** STERO_BUFFER_SIZE_BITS
defc STEREO_BUFFER_H_MASK = (STEREO_BUFFER_SIZE - 1) >> 8
defc STEREO_BUFFER_H_OVERFLOW_BIT = STERO_BUFFER_SIZE_BITS - 8
defc STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT = STEREO_BUFFER_H_OVERFLOW_BIT + 1

defc MONO_BUFFER_SIZE_BITS = STERO_BUFFER_SIZE_BITS - 1 ; Mono buffer is half the size of stereo buffer
defc MONO_BUFFER_SIZE = 2 ** MONO_BUFFER_SIZE_BITS
defc MONO_BUFFER_H_MASK = (MONO_BUFFER_SIZE - 1) >> 8
defc MONO_BUFFER_H_OVERFLOW_BIT = MONO_BUFFER_SIZE_BITS - 8
defc MONO_DOUBLE_BUFFER_H_OVERFLOW_BIT = MONO_BUFFER_H_OVERFLOW_BIT + 1

defc SOUND_EOF_MARKER = 0xFF

; ---------------------------------------------------------------
; Interrupt handler for stero + mono sound playback
; ---------------------------------------------------------------

sound_interrupt_handler:
    push af
    push hl

    ld a, stereo_samples_buffer >> 16
    call set_mmu_data_page_di

    call process_stereo_sound_channel
    call process_mono_sound_channel

    call restore_mmu_data_page_di

    pop hl
    pop af
    ei
    reti

process_stereo_sound_channel:
    ; returns if buffers are empty
    ld a, (stereo_samples_channel + SC_REMAINING_BUFFERS)
    and a
    ret z

    ld hl, (stereo_samples_channel + SC_CURSOR)
    ld a, (hl)
    cp SOUND_EOF_MARKER         ; Check for end-of-buffer marker
    jr nz, stereo_output_sample
    
    xor a
    ld (stereo_samples_channel + SC_REMAINING_BUFFERS), a
    ret

stereo_output_sample:
    nextreg REG_DAC_LEFT, a
    inc hl
    ld a, (hl)
    nextreg REG_DAC_RIGHT, a
    inc hl

    res STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (stereo_samples_channel + SC_CURSOR), hl

    ld a, h
    and STEREO_BUFFER_H_MASK
    or l
    ret nz

    ; End of buffer reached
    ld hl, stereo_samples_channel + SC_REMAINING_BUFFERS
    dec (hl)
    ret

process_mono_sound_channel:
    ; returns if both buffers are empty
    ld a, (mono_samples_channel + SC_REMAINING_BUFFERS)
    and a
    ret z

    ld hl, (mono_samples_channel + SC_CURSOR)
    ld a, (hl)
    cp SOUND_EOF_MARKER         ; Check for end-of-buffer marker
    jr nz, mono_output_sample
    
    xor a
    ld (mono_samples_channel + SC_REMAINING_BUFFERS), a
    ret

mono_output_sample:
    nextreg REG_DAC_MONO, a
    inc hl

    res MONO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (mono_samples_channel + SC_CURSOR), hl

    ld a, h
    and MONO_BUFFER_H_MASK
    or l
    ret nz

    ; End of buffer reached
    ld hl, mono_samples_channel + SC_REMAINING_BUFFERS
    dec (hl)
    ret

; ---------------------------------------------------------------
; End of interrupt service routines
; ---------------------------------------------------------------

SECTION data_user

; Sound channel data structure
  DEFVARS 0               
  {
    SC_CURSOR                DS.W 1       ; current cursor in the buffer
    SC_REMAINING_BUFFERS     DS.B 1       ; 2 = paused

    SC_FILE_HANDLE           DS.B 1       ; file handle associated to the channel
    SC_BUFFER_AREA           DS.B 1       ; buffer area address (high byte)
    SC_BUFFER_SIZE           DS.B 1       ; buffer size (high byte = size / 256)
    SC_NEXT_BUFFER           DS.B 1       ; next buffer index 
    SC_STRUCT_SIZE    
  } 

stereo_samples_channel:
    defw stereo_samples_buffer & 0xFFFF         ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default

mono_samples_channel:
    defw mono_samples_buffer & 0xFFFF           ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default

SECTION sound_data

stereo_samples_buffer: 
left_channel_samples_buffer:
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER

right_channel_samples_buffer:
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER

mono_samples_buffer: 
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER


