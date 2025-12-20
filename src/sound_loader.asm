INCLUDE "config_zxn_private.inc"
INCLUDE "macros.inc"

SECTION code_user

PUBLIC _load_sound_file, sound_loader_read_buffer
EXTERN _sample_pointer
EXTERN _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

// TODO: add to general library in z88dk
defc __IO_CTC0 = 0x183B // CTC channel 0 port


defc INT_CTC_CHANNEL_0 = 3

sound_loader_read_buffer:   
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

_load_sound_file:
    ; Stops CTC channel 0
    ; ld bc, __IO_CTC0
    ; ld a, 0b00000001
    ; out (c), a
    push hl ; saves the filename pointer
    ; Closes previous file if any
    ld a, (sound_file_handler)
    cp -1
    call nz, close_handler ; Close previous file if any
    pop ix  ; IX points to the null terminated filename string
    ld a, '*'
    ld b, __ESXDOS_MODE_READ
    rst __ESX_RST_SYS
    defb __ESX_F_OPEN
    jr nc, file_exists
    ld a, -1
    ld (sound_file_handler), a
    ld l,a
    ; There was an error opening the file
    ret
file_exists:
    ld (sound_file_handler), a
    ; Saves the current page in MMU 6
    READ_NEXTREG(REG_MMU6)
    push af
    ld a, _SOUND_SAMPLES_BUFFER >> 16
    nextreg REG_MMU6, a
    ; Fills both buffers
    ld ix, _SOUND_SAMPLES_BUFFER
    call sound_loader_read_buffer
    ld ix, _SOUND_SAMPLES_BUFFER + _SOUND_SAMPLES_BUFFER_SIZE
    call sound_loader_read_buffer
    ; sets the sample pointer to the start of the first buffer
    ld hl, _SOUND_SAMPLES_BUFFER
    ld (_sample_pointer), hl
    ; Restores the currengt page in MMU 6
    pop af
    nextreg REG_MMU6, a
    ld l, 0
    ret


SECTION data_user

sound_file_handler: 
    defb -1
