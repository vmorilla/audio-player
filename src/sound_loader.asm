INCLUDE "config_zxn_private.inc"
INCLUDE "macros.inc"

SECTION code_user

PUBLIC _sound_loader_handler, _play_sound_file, _sound_loader_interrupt_handler
EXTERN _sample_pointer, _empty_buffers_mask
EXTERN _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

_sound_loader_interrupt_handler:
    ei
    call _sound_loader_handler
    reti


_sound_loader_handler:
    push af
    ld a, (sound_file_handler)
    cp -1
    jr z, _sound_loader_handler_end ; No file open
    ld a, (_empty_buffers_mask)
    and a
    jr z, _sound_loader_handler_end ; No empty buffers
    push ix
    push bc
    push de
    push hl
    bit 3, a
    jr z, load_buffer_1
load_buffer_0:
    ld ix, _SOUND_SAMPLES_BUFFER    
    call sound_loader_read_buffer
    ld hl, _empty_buffers_mask
    res 3, (hl)
    jr _sound_loader_handler_end1
load_buffer_1:
    ld ix, _SOUND_SAMPLES_BUFFER + _SOUND_SAMPLES_BUFFER_SIZE
    call sound_loader_read_buffer
    ld hl, _empty_buffers_mask
    res 4, (hl) 
_sound_loader_handler_end1:
    pop hl
    pop de
    pop bc
    pop ix
_sound_loader_handler_end:
    pop af
    ret

; IX: following address to read data into
sound_loader_read_buffer:   
    READ_NEXTREG(REG_MMU6)
    push af
    NEXTREG REG_MMU6, _SOUND_SAMPLES_BUFFER >> 16
    ld a, (sound_file_handler)
    ld bc, _SOUND_SAMPLES_BUFFER_SIZE
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    pop af
    NEXTREG REG_MMU6, a
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
read_buffer_close_handler:
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
