
PUBLIC samples_counter_interrupt_handler
PUBLIC _sound_samples_played


EXTERN stereo_samples_channel, SC_CURSOR, STEREO_BUFFER_SIZE

SECTION code_user

samples_counter_interrupt_handler:
    push af
    push de
    push hl

    ; calculate samples played by substracting the the last sample pointer from the current sample pointer
    ld de, (last_sample_pointer)
    ld hl, (stereo_samples_channel + SC_CURSOR)
    
    ei
    ld (last_sample_pointer), hl
    and a
    sbc hl, de
    jr nc, no_carry
    ld de, STEREO_BUFFER_SIZE * 2
    add hl, de
no_carry:
    ld (_sound_samples_played), hl

    pop hl
    pop de
    pop af
    reti

SECTION data_user

last_sample_pointer:
    defw 0
_sound_samples_played:
    defw 0
