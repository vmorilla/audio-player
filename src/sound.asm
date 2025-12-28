
SECTION code_user

INCLUDE "config_zxn_private.inc"
INCLUDE "zxn_constants.h"

PUBLIC _play_sound_file, _update_sound_channels
PUBLIC stereo_samples_channel, mono_samples_channel
PUBLIC SC_CURSOR, SC_REMAINING_BUFFERS

EXTERN MONO_BUFFER_SIZE, STEREO_BUFFER_SIZE, SOUND_EOF_MARKER
EXTERN stereo_samples_buffer, mono_samples_buffer
EXTERN _set_mmu_data_page, _restore_mmu_data_page

defc BUFFERS_MMU_PAGE = stereo_samples_buffer >> 16

; ---------------------------------------------------------------------------
; read_buffer: reads the buffer corresponding to the channel in IY
; ---------------------------------------------------------------------------
read_buffer:
    ld a, (iy + SC_FILE_HANDLE)

    ; Size in bc 
    ld b, (iy + SC_BUFFER_SIZE)
    ld c,0

    ld d, (iy + SC_BUFFER_AREA)
    ld ixh, d
    ld ixl, c

    bit 0, (iy + SC_NEXT_BUFFER)
    jr z, read_buffer_first_buffer
    add ix, bc

read_buffer_first_buffer:
    call f_read
    jr z, read_buffer_complete

    // Marks the end of the buffer
    ld (ix + 0), SOUND_EOF_MARKER

    // Closes the file handle
    ld a, (iy + SC_FILE_HANDLE)
    call f_close
    ld (iy + SC_FILE_HANDLE), -1

read_buffer_complete:
    inc (iy + SC_REMAINING_BUFFERS)
    inc (iy + SC_NEXT_BUFFER)
    ret

; ---------------------------------------------------------------------------
; int8_t play_sound_file(SoundChannel channel, const char *filename);
; ---------------------------------------------------------------------------

_play_sound_file:
    push ix
    ld ix, 4
    add ix, sp
    push iy

    ld e, (ix + 0) ; channel id
    call get_channel_from_parameter

    ; Pauses the sound channel
    ld (iy + SC_REMAINING_BUFFERS), 0 ; pauses the channel

    ; Closes previous file if any
    ld a, (iy + SC_FILE_HANDLE)
    cp -1
    call nz, f_close ; Close previous file if any

    ld hl, (ix + 1) ; filename parameter

    call f_open
    jr nc, _play_sound_file_exists
    ; There was an error opening the file
    ld (iy + SC_FILE_HANDLE), -1
    ld l, -1
    jr _play_sound_file_end

_play_sound_file_exists:
    ; Stores the file handle
    ld (iy + SC_FILE_HANDLE), a

    ; Resets next buffer and cursor
    xor a
    ld (iy + SC_NEXT_BUFFER), a
    ld (iy + SC_CURSOR), a
    ld a, (iy + SC_BUFFER_AREA)
    ld (iy + SC_CURSOR + 1), a

    ld l, BUFFERS_MMU_PAGE
    call _set_mmu_data_page

    call read_buffer

    call _restore_mmu_data_page

    ld l, (iy + SC_FILE_HANDLE) ; success

_play_sound_file_end:
    pop iy
    pop ix
    ret


; ---------------------------------------------------------------------------
; void _update_sound_channels(void)
; Checks if any sound channels needs to be updated. 
; At most, it updates one channel per call
; ---------------------------------------------------------------------------

_update_sound_channels:
    push iy

    ld iy, stereo_samples_channel
    call _update_invidiual_channel

    ld iy, mono_samples_channel
    call z, _update_invidiual_channel

    pop iy
    ret

; Returns with Z flag set if the channel was not updated
_update_invidiual_channel:
    ld a, (iy + SC_REMAINING_BUFFERS)
    cp 2
    ret z

    ld a, (iy + SC_FILE_HANDLE)
    inc a
    ret z

    ld l, BUFFERS_MMU_PAGE
    call _set_mmu_data_page

    call read_buffer

    call _restore_mmu_data_page

    or 1

    ret

; Input:
; E = channel parameter
; Output:
; IY = pointer to sound channel data structure
; Modifies: DE, A
get_channel_from_parameter:
    sla e
    ld d, 0
    add de, channels_table
    ld a, (de)
    ld iyl, a
    inc de
    ld a, (de)
    ld iyh, a
    ret

; ----------------------------------------------------------------------
; ESXDOS routines
; ----------------------------------------------------------------------


; ----------------------------------------------------------------------
; A = file handle
; Rewinds the file to the beginning
; IX and BC are preserved
; ----------------------------------------------------------------------
f_rewind:
    push bc ; save current buffer position
    push ix ; save remaining bytes to fill
    ld ixl, 0   ; esx_seek_set
    ld bc, 0   ; bcde = offset 0
    ld de, 0
    rst __ESX_RST_SYS
    defb __ESX_F_SEEK
    pop ix ; restore buffer position
    pop bc ; restore bytes to fill
    ret 

; ----------------------------------------------------------------------
; A = file handle
; ----------------------------------------------------------------------
f_close:
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE
    ret


; ----------------------------------------------------------------------
; Reads data from a file into a buffer
;
; IX = buffer pointer
; BC = bytes to read
; A = file handle
; Output:
; IX = updated buffer pointer
; HL = pending bytes to read
; BC and DE = bytes actually read
; Z flag set if buffer completely filled
; ----------------------------------------------------------------------
f_read:
    ; Input: 
    ;   IX = buffer pointer, 
    ;   BC = bytes to read, 
    ;   A = file handle
    ; Output: 
    ;   IX = updated buffer pointer, 
    ;   HL = pending bytes to read, 
    ;   BC and DE = bytes actually read
    ;   Z flag set if buffer completely filled

    push bc
    rst __ESX_RST_SYS
    defb __ESX_F_READ
    ; Output: HL = updated buffer pointer, BC and DE = bytes actually read
    push hl
    pop ix ; <-- updated buffer pointer
    pop hl ; <-- size to read
    sbc hl, bc
    ld a, l
    or h
    
    ret

; ----------------------------------------------------------------------
; Opens a file
; Input: HL = filename pointer
; Output: A = file handle or error code
; ----------------------------------------------------------------------
f_open:
    ld ix, hl
    ld a, '*'
    ld b, __ESXDOS_MODE_READ

    rst __ESX_RST_SYS
    defb __ESX_F_OPEN

    ret

; ----------------------------------------------------------------------

SECTION data_user

channels_table:
    defw stereo_samples_channel
    defw mono_samples_channel
; Sound channel source data structure
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
    defb -1                                     ; file handle
    defb (stereo_samples_buffer >> 8) & 0xFF    ; buffer area address (high byte)
    defb STEREO_BUFFER_SIZE >> 8                ; buffer size (high byte)
    defb 0                                      ; next buffer index 

mono_samples_channel:
    defw mono_samples_buffer & 0xFFFF           ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default
    defb -1                                     ; file handle 
    defb (mono_samples_buffer >> 8) & 0xFF      ; buffer area address (high byte)
    defb MONO_BUFFER_SIZE >> 8                  ; buffer size (high byte)
    defb 0                                      ; next buffer index



