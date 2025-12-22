PUBLIC _samples_counter_interrupt_handler, _sound_samples_played
EXTERN _sample_pointer, _SOUND_SAMPLES_BUFFER_SIZE

SECTION code_user

_samples_counter_interrupt_handler:
    push af
    push de
    push hl

    ; calculate samples played by substracting the the last sample pointer from the current sample pointer
    ld de, (_last_sample_pointer)
    ld hl, (_sample_pointer)
    
    ei
    ld (_last_sample_pointer), hl
    and a
    sbc hl, de
    jr nc, no_carry
    ld de, _SOUND_SAMPLES_BUFFER_SIZE * 2
    add hl, de
no_carry:
    ld (_sound_samples_played), hl

    pop hl
    pop de
    pop af
    reti

SECTION data_user

_last_sample_pointer:
    defw 0
_sound_samples_played:
    defw 0
