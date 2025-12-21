
SECTION code_user

PUBLIC _sound_interrupt_handler
PUBLIC _sample_pointer
PUBLIC _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

EXTERN sound_loader_read_buffer, _set_mmu_data_page, _restore_mmu_data_page

defc BUFFER_SIZE_BITS = 10 ; 11 bits -> 2048 bytes stereo buffer, 10 bits -> 1024 bytes stereo buffer
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
    push de
    push hl
    push ix
    ld l, _SOUND_SAMPLES_BUFFER >> 16
    call _set_mmu_data_page

    ld hl, (_sample_pointer)
    ld a, (hl)
    cp 0xFF         ; Check for end-of-buffer marker 
    jr z, end_interrupt

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
    ld ix, _SOUND_SAMPLES_BUFFER
    bit BUFFER_H_OVERFLOW_BIT, h    ; If this bit is set, the first buffer has been consumed
    jr nz, read_buffer
    ld ix, _SOUND_SAMPLES_BUFFER + _SOUND_SAMPLES_BUFFER_SIZE
read_buffer:
    call sound_loader_read_buffer
    jr end_interrupt

no_end_of_buffer:
    ld (_sample_pointer), hl
    ; Restores the currengt page in MMU 6
end_interrupt:
    call _restore_mmu_data_page
    pop ix
    pop hl
    pop de
    pop bc
    pop af
    reti
; ---------------------------------------------------------------    

SECTION data_user

_sample_pointer:
    defw SAMPLES_BUFFER & 0xFFFF
_end_sample_pointer:
    defw (SAMPLES_BUFFER + 2 * BUFFER_SIZE) & 0xFFFF
