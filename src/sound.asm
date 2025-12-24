
SECTION code_user

PUBLIC _sound_interrupt_handler
PUBLIC _stereo_samples_pointer, _stereo_channel_paused
PUBLIC _STEREO_SAMPLES_BUFFER_SIZE, _stereo_samples_buffer

EXTERN sound_loader_read_buffer, set_mmu_data_page_di, restore_mmu_data_page_di

defc STERO_BUFFER_SIZE_BITS = 10 ; 11 bits -> 2048 bytes stereo buffer, 10 bits -> 1024 bytes stereo buffer
defc STEREO_BUFFER_SIZE = 2 ** STERO_BUFFER_SIZE_BITS
defc STEREO_BUFFER_H_MASK = (STEREO_BUFFER_SIZE - 1) >> 8
defc STEREO_BUFFER_H_OVERFLOW_BIT = STERO_BUFFER_SIZE_BITS - 8
defc STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT = STEREO_BUFFER_H_OVERFLOW_BIT + 1
defc SOUND_EOF_MARKER = 0xFF

; TODO: add to general library in z88dk
defc REG_DAC_LEFT = 0x2C
defc REG_DAC_MONO = 0x2D
defc REG_DAC_RIGHT = 0x2E  

; Exported symbols
defc _STEREO_SAMPLES_BUFFER_SIZE = STEREO_BUFFER_SIZE

; Sound channel data structure
  DEFVARS 0               
  {
    SOUND_CHANNEL_PAUSED       DS.B 1       ; 1 = paused, 0 = playing
    SOUND_CHANNEL_CURSOR       DS.W 1       ; current cursor in the buffer
    SOUND_CHANNEL_BUFFER_SIZE  DS.W 1       ; size of the buffer 
    SOUND_CHANNEL_STRUCT_SIZE    
  }


_sound_interrupt_handler:
    push af
    push hl

    ld a, (_stereo_samples_channel + SOUND_CHANNEL_PAUSED)
    and a
    jr nz, end_interrupt_fast ; channel paused

    ld a, _stereo_samples_buffer >> 16
    call set_mmu_data_page_di

    ld hl, (_stereo_samples_pointer)
    ld a, (hl)
    cp 0xFF         ; Check for end-of-buffer marker 
    jr z, end_interrupt

    nextreg REG_DAC_LEFT, a
    inc hl
    ld a, (hl)
    nextreg REG_DAC_RIGHT, a
    inc hl
    ld a, h
    and STEREO_BUFFER_H_MASK
    or l
    jr z, end_of_buffer

    ld (_stereo_samples_pointer), hl

end_interrupt:
    ; Restores the currengt page in MMU 6
    call restore_mmu_data_page_di
end_interrupt_fast:
    pop hl
    pop af
    ei
    reti

end_of_buffer:

    res STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (_stereo_samples_pointer), hl

    ; signals that the ISR is done and continues to update buffers
    push buffer_needs_update
    ei
    reti

buffer_needs_update:
    ; saves the rest of registers
    push bc
    push de
    push ix
    ld ix, _stereo_samples_buffer
    bit STEREO_BUFFER_H_OVERFLOW_BIT, h    ; If this bit is set, the first buffer has been consumed
    jr nz, read_buffer
    ld ix, _stereo_samples_buffer + _STEREO_SAMPLES_BUFFER_SIZE
read_buffer:
    call sound_loader_read_buffer
    ; restores registers
    pop ix
    pop de
    pop bc
    ; Restores the currengt page in MMU 6
    di
    call restore_mmu_data_page_di
    ; Restores registers saved at the beginning of the interrupt
    pop hl
    pop af
    ei
    ret ; <--- reti was already called  

; ---------------------------------------------------------------    

SECTION data_user

defc _stereo_channel_paused = _stereo_samples_channel + SOUND_CHANNEL_PAUSED
defc _stereo_samples_pointer = _stereo_samples_channel + SOUND_CHANNEL_CURSOR
_stereo_samples_channel:
    defb 1
    defw _stereo_samples_buffer & 0xFFFF
    defw STEREO_BUFFER_SIZE

SECTION sound_data


_stereo_samples_buffer: 
    defs STEREO_BUFFER_SIZE * 2, SOUND_EOF_MARKER

