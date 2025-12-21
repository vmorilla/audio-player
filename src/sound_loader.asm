INCLUDE "config_zxn_private.inc"

SECTION code_user

PUBLIC _load_sound_file, sound_loader_read_buffer, _loop_mode
EXTERN _sample_pointer, _default_interrupt_handler, _interrupt_vector_table
EXTERN _set_mmu_data_page, _restore_mmu_data_page
EXTERN _SOUND_SAMPLES_BUFFER_SIZE, _SOUND_SAMPLES_BUFFER

// TODO: add to general library in z88dk
defc __IO_CTC0 = 0x183B // CTC channel 0 port
defc INT_CTC_CHANNEL_0 = 3

sound_loader_read_buffer:   
    ld a, (sound_file_handler)
    cp -1
    jr nz, load_chunk
    ld hl, countdown_to_stop
    dec (hl)
    ret nz
    ; Stops sound playback
    di
    ; Disables CTC channel 0 interrupt
    ld hl, _interrupt_vector_table + (INT_CTC_CHANNEL_0 * 2)
    ld (hl), _default_interrupt_handler & 0xFF
    inc hl
    ld (hl), _default_interrupt_handler >> 8
    ret
load_chunk:
    ld bc, _SOUND_SAMPLES_BUFFER_SIZE
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    ld de, hl
    ld hl, _SOUND_SAMPLES_BUFFER_SIZE
    sbc hl, bc
    ld a, l
    or h
    ret z ; buffer complete. We did not reach EOF
    ; The buffer has not been completely filled (file reached EOF)
    ld a, (_loop_mode)
    and a
    jr z, fill_buffer
    // Loop mode...
    push de ; save current buffer position
    push hl ; save remaining bytes to fill
    ld a, (sound_file_handler)
    ld ixl, 0   ; esx_seek_set
    ld bc, 0   ; bcde = offset 0
    ld de, 0
    rst __ESX_RST_SYS
    defb __ESX_F_SEEK
    ; Now read again to fill the rest of the buffer
    ld a, (sound_file_handler)
    pop bc ; restore bytes to fill
    pop ix ; restore buffer position
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    ret  

fill_buffer:
    ; We fill the rest of the buffer with 128 (silence)
    ld bc, hl
    ld hl, de
    dec bc
    ld (hl), 128
    ld a, b
    or c
    jr z, close_handler
    inc de
    ldir
    jr close_handler

close_handler:
    ld a, (sound_file_handler)
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE
    ld a, -1
    ld (sound_file_handler), a
    ld a, 2
    ld (countdown_to_stop), a
    ret


; int8_t load_sound_file(const char *filename, bool loop);
_load_sound_file:
    ; Closes previous file if any
    ld a, (sound_file_handler)
    cp -1
    call nz, close_handler ; Close previous file if any
    ld ix, 2
    add ix, sp
    ld a, (ix + 2) ; loop parameter
    ld (_loop_mode), a
    ld hl, (ix + 0) ; filename parameter
    ld ix, hl
    ld a, '*'
    ld b, __ESXDOS_MODE_READ
    rst __ESX_RST_SYS
    defb __ESX_F_OPEN
    jr nc, file_exists
    ; There was an error opening the file
    ld a, -1
    ld (sound_file_handler), a
    ld l,a
    ret
file_exists:
    ld (sound_file_handler), a
    ; Saves the current page in MMU 6

    ; Sets data page
    ld l, _SOUND_SAMPLES_BUFFER >> 16
    call _set_mmu_data_page

    ; Fills both buffers
    ld ix, _SOUND_SAMPLES_BUFFER
    call sound_loader_read_buffer
    ld ix, _SOUND_SAMPLES_BUFFER + _SOUND_SAMPLES_BUFFER_SIZE
    call sound_loader_read_buffer
    ; sets the sample pointer to the start of the first buffer
    ld hl, _SOUND_SAMPLES_BUFFER
    ld (_sample_pointer), hl
    ; Restores the currengt page in MMU 6
    call _restore_mmu_data_page
    ; Returns 0 = success
    ld l, 0
    ret


SECTION data_user

sound_file_handler: 
    defb -1
countdown_to_stop:
    defb 10 ; number of buffers with no file handler before stopping sound playback
_loop_mode:
    defb 0 ; 0 = no loop, 1 = loop sound file