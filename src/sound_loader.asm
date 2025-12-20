INCLUDE "config_zxn_private.inc"
INCLUDE "macros.inc"

SECTION code_user

PUBLIC _play_sound_file, lsound_loader_read_buffer
EXTERN _sample_pointer
EXTERN _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER


lsound_loader_read_buffer:   
    ld a, (sound_file_handler)
    cp -1
    ret z
    ld bc, _SOUND_SAMPLES_BUFFER_SIZE
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    ld de, hl
    ld hl, _SOUND_SAMPLES_BUFFER_SIZE
    sbc hl, bc
    ld a, l
    or h
    ret z ; buffer complete
    ld bc, hl
    ld hl, de
    dec bc
    ld (hl), 0
    ld a, b
    or c
    jr close_handler
    inc de
    ldir
    ; The buffer has not been completely filled (file reached EOF)
    jr close_handler




close_handler:
    ld a, (sound_file_handler)
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE
    ld a, -1
    ld (sound_file_handler), a
    ret

_play_sound_file:
    push ix
    push hl
    pop ix  ; IX points to the null terminated filename string
    ld a, '*'
    ld b, __ESXDOS_MODE_READ
    rst __ESX_RST_SYS
    defb __ESX_F_OPEN
    jr nc, file_opened
    ld a, -1
    ld (sound_file_handler), a
    ld l,a
    ; There was an error opening the file
    pop ix
    ret
file_opened:
    ld (sound_file_handler), a
    pop ix
    ld l,a
    ret


SECTION data_user

sound_file_handler: 
    defb -1
