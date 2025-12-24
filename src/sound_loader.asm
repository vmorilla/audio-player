INCLUDE "config_zxn_private.inc"

SECTION code_user

PUBLIC _play_sound_file, _queue_sound_file, sound_loader_read_buffer
EXTERN _stereo_samples_pointer, _stereo_channel_paused
EXTERN _set_mmu_data_page, _restore_mmu_data_page
EXTERN _STEREO_SAMPLES_BUFFER_SIZE, _stereo_samples_buffer

sound_loader_read_buffer:   
    ld a, (sound_file_handler)
    ; TODO: not necessary?
    cp -1
    ret z ; no file opened 
load_chunk:
    ld bc, _STEREO_SAMPLES_BUFFER_SIZE
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    ld de, hl
    ld hl, _STEREO_SAMPLES_BUFFER_SIZE
    sbc hl, bc
    ld a, l
    or h
    ret z ; buffer complete. We did not reach EOF
    ; The buffer has not been completely filled (file reached EOF)
    
    ; First, we check if we have a new handler in the queue
    ld a, (queued_sound_file_handler)
    cp -1
    jr z, check_loop_mode ; no new handler

    ; First, we save the current buffer position and remaining bytes to fill before closing the current handler
    push de ; save current buffer position
    push hl ; save remaining bytes to fill
    call close_handler
    ld a, (queued_sound_file_handler)
    ld (sound_file_handler), a
    ld a, (queued_file_loop_mode)
    ld (loop_mode), a
    ld a, -1
    ld (queued_sound_file_handler), a
    jr load_rest_of_buffer

check_loop_mode:
    ld a, (loop_mode)
    and a
    jr nz, rewind
    dec a  ; a = 0xff
    ld (de), a  ; end marker
    jr close_handler
rewind:
    // Loop mode...
    push de ; save current buffer position
    push hl ; save remaining bytes to fill
    ld a, (sound_file_handler)
    ld ixl, 0   ; esx_seek_set
    ld bc, 0   ; bcde = offset 0
    ld de, 0
    rst __ESX_RST_SYS
    defb __ESX_F_SEEK

load_rest_of_buffer:
    ; Now read again to fill the rest of the buffer
    pop bc ; restore bytes to fill
    pop ix ; restore buffer position
    ld a, (sound_file_handler)
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    ret  

close_handler:
    ld a, (sound_file_handler)
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE
    ld a, -1
    ld (sound_file_handler), a
    ret


; int8_t load_sound_file(const char *filename, bool loop);
_play_sound_file:
    push ix
    ; Pauses the sound channel
    ld a, 1
    ld (_stereo_channel_paused), a ; reset pointer

    ; Closes previous file if any
    ld a, (sound_file_handler)
    cp -1
    call nz, close_handler ; Close previous file if any
    ld ix, 4
    add ix, sp
    ld a, (ix + 2) ; loop parameter
    ld (loop_mode), a
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
    pop ix
    ret
file_exists:
    ld (sound_file_handler), a
    ; Saves the current page in MMU 6

    ; Sets data page
    ld l, _stereo_samples_buffer >> 16
    call _set_mmu_data_page

    ; Fills both buffers
    ld ix, _stereo_samples_buffer
    call sound_loader_read_buffer
    ld ix, _stereo_samples_buffer + _STEREO_SAMPLES_BUFFER_SIZE
    call sound_loader_read_buffer

    ; sets the sample pointer to the start of the first buffer
    ld hl, _stereo_samples_buffer
    ld (_stereo_samples_pointer), hl

    ; Enables the sound channel
    xor a
    ld (_stereo_channel_paused), a ; reset pointer

    ; Restores the currengt page in MMU 6
    call _restore_mmu_data_page
    ; Returns 0 = success
    ld l, 0
    pop ix
    ret

; int8_t load_sound_file(const char *filename, bool loop);
_queue_sound_file:
    push ix
    ; Closes previous file if any
    ld a, (queued_sound_file_handler)
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE
    
    ld ix, 4
    add ix, sp
    ld a, (ix + 2) ; loop parameter
    ld (queued_file_loop_mode), a
    ld hl, (ix + 0) ; filename parameter
    ld ix, hl
    ld a, '*'
    ld b, __ESXDOS_MODE_READ
    rst __ESX_RST_SYS
    defb __ESX_F_OPEN
    jr nc, queue_file_exists
    ; There was an error opening the file
    ld a, -1
queue_file_exists:
    ld (queued_sound_file_handler), a
    ld l,a
    pop ix
    ret


SECTION data_user




sound_file_handler: 
    defb -1
loop_mode:
    defb 0 ; 0 = no loop, 1 = loop sound file

queued_sound_file_handler:
    defb -1
queued_file_loop_mode:
    defb 0 ; 0 = no loop, 1 = loop sound file