
SECTION code_user

INCLUDE "config_zxn_private.inc"
INCLUDE "zxn_constants.h"

PUBLIC _play_sound_file 

EXTERN sound_interrupt_handler
EXTERN stereo_samples_channel, mono_samples_channel
EXTERN STEREO_BUFFER_SIZE, MONO_BUFFER_SIZE
EXTERN SC_CURSOR, SC_REMAINING_BUFFERS, SOUND_EOF_MARKER

EXTERN set_mmu_data_page_di, restore_mmu_data_page_di


stereo_buffer_needs_update:
    ; saves the rest of registers
    push bc
    push de
    push ix
    push iy
    ld iy, stereo_samples_channel
    ld ix, stereo_samples_buffer
    ld bc, STEREO_BUFFER_SIZE
    bit STEREO_BUFFER_H_OVERFLOW_BIT, h    ; If this bit is set, the first buffer has been consumed
    jr nz, buffer_needs_update
    add ix, bc
buffer_needs_update:
    call f_acquire_semaphore
    call sound_loader_read_buffer
    call f_release_semaphore
    ; restores registers
    pop iy
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

mono_buffer_needs_update:
    ; saves the rest of registers
    ; saves the rest of registers
    push bc
    push de
    push ix
    push iy
    ld iy, mono_samples_channel
    ld ix, mono_samples_buffer
    ld bc, MONO_BUFFER_SIZE
    bit MONO_BUFFER_H_OVERFLOW_BIT, h    ; If this bit is set, the first buffer has been consumed
    jr nz, buffer_needs_update
    add ix, bc
    jr buffer_needs_update
; ---------------------------------------------------------------    

make_callback:
    ; We save additional registers since the user function might use them
    ; We will assume that alt registers are preserved by the user function
    ; af and hl are already saved
    push bc
    push de
    push ix
    push iy

    exx
    push bc
    push de
    push hl
    exx
    
    ex af, af'
    push af
    ex af, af'
    
    ; Saves the point to return after the callback
    push return_from_callback

    ; Prepares the callback function call and sets it to zero
    ld e, (hl)
    ld (hl), 0
    inc hl
    ld d, (hl)
    ; Saves the callback address
    push de
    ; Call back with the previous MMU data page
    call restore_mmu_data_page_di

    ei
    reti ; we jump to the callback function  
return_from_callback:
    ex af, af'
    pop af
    ex af, af'

    exx
    pop hl
    pop de
    pop bc
    exx
    
    ; We return safely from the callback
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af
    ret

; ---------------------------------------------------------------------------

; Loads data into the buffer pointed by IX and length indicated by BC from the file handle pointed by HL

; IY = channel data structure
; IX = buffer pointer
; BC = bytes to read
sound_loader_read_buffer:   
    ld a, (IY + SC_FILE_HANDLE)
load_chunk:
    ; Input: IX = buffer pointer, BC = bytes to read, A = file handle
    call f_read
    ret z ; buffer complete. We did not reach EOF

    ; The buffer has not been completely filled (file reached EOF)
    bit 7, (IY + SC_QUEUED_FILE_HANDLE)
    jr nz, check_loop_mode ; No queued file, check loop mode
    
    ; Queued file found, switch to it
    ; First close current handler
    ld a, (IY + SC_FILE_HANDLE)
    call f_close

    ld a, (IY + SC_QUEUED_FILE_HANDLE)
    ld (IY + SC_FILE_HANDLE), a
    ld (IY + SC_QUEUED_FILE_HANDLE), -1
    jr load_chunk

check_loop_mode:
    bit 0, (IY + SC_LOOP_MODE)
    jr z, nothing_more_to_read

    ld a, (iy + SC_FILE_HANDLE)
    // Rewind...
    call f_rewind
    jr sound_loader_read_buffer

nothing_more_to_read:
    ; Mark end of buffer with 0xff
    ld a, SOUND_EOF_MARKER
    ld (ix), a
    ret

; ---------------------------------------------------------------------------
; int8_t play_sound_file(SoundChannel channel, const char *filename, bool loop);
; ---------------------------------------------------------------------------

_play_sound_file:
    push ix
    ld ix, 4
    add ix, sp
    push iy
    call get_channel_from_parameter

    ; Pauses the sound channel
    ld (iy + SC_PAUSED), 1 ; pauses the channel

    ; Closes previous file if any
    ld a, (iy + SC_FILE_HANDLE)
    cp -1
    call nz, f_close ; Close previous file if any

    ld a, (ix + 3) ; loop parameter
    ld (iy + SC_LOOP_MODE), a
    ld hl, (ix + 1) ; filename parameter

    call f_open
    jr nc, file_exists
    ; There was an error opening the file
    ld (iy + SC_FILE_HANDLE), -1
    ld l,a

    pop iy
    pop ix
    call f_release_semaphore
    ret


file_exists:
    ld (iy + SC_FILE_HANDLE), a

    ; Sets data page
    ld l, stereo_samples_buffer >> 16
    call _set_mmu_data_page

    ; Fills both buffers
    ld ix, (iy + SC_BUFFER_AREA)
    ; sets the sample pointer to the start of the first buffer
    ld (iy + SC_CURSOR), ix

    ld bc, (iy + SC_BUFFER_AREA_SIZE)
    call sound_loader_read_buffer

    ; Enables the sound channel
    ld (iy + SC_PAUSED), 0 ; resumes the channel

    ; Restores the currengt page in MMU 6
    call _restore_mmu_data_page
    ; Returns 0 = success
    ld l, 0

    pop iy
    pop ix

    call f_release_semaphore

    ret

; ---------------------------------------------------------------------------
; int8_t queue_sound_file(SoundChannel channel, const char *filename, bool loop);
; ---------------------------------------------------------------------------

_queue_sound_file:
    call f_acquire_semaphore
    push ix
    ld ix, 4
    add ix, sp
    push iy
    call get_channel_from_parameter

    ; Closes previous file if any
    ld a, (iy + SC_QUEUED_FILE_HANDLE)
    cp -1
    call nz, f_close ; Close previous file if any
    
    ld a, (ix + 3) ; loop parameter
    ld (iy + SC_LOOP_MODE), a
    ld hl, (ix + 1) ; filename parameter
    call f_open

    jr nc, queue_file_exists
    ; There was an error opening the file
    ld a, -1
queue_file_exists:
    ld (iy + SC_QUEUED_FILE_HANDLE), a
    ld l,a
    pop iy
    pop ix
    call f_release_semaphore
    ret

; ---------------------------------------------------------------------------

; Input:
; IX + 0 = channel parameter
; Output:
; IY = pointer to sound channel data structure
get_channel_from_parameter:
    ld e, (ix + 0) ; channel parameter
    sla e
    ld d, 0
    ld hl, channels_table
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    push de
    pop iy
    ret


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

    ; Opens a file
    ; Input: HL = filename pointer
    ; Output: A = file handle or error code
f_open:
    ld ix, hl
    ld a, '*'
    ld b, __ESXDOS_MODE_READ
    call __trace_registers
    defb "o: \0"

    rst __ESX_RST_SYS
    defb __ESX_F_OPEN

    call __trace_registers
    defb "O: \0"

    ret
    ; ----------------------------------------------------------------------

f_acquire_semaphore:
    ; Acquires the ESXDOS semaphore
__acquire_loop:
    ld hl, _esxdos_semaphore
    dec (hl)
    ret z ; acquired
    inc (hl)
    halt
    jr __acquire_loop

f_release_semaphore:
    ; Releases the ESXDOS semaphore
    push hl
    ld hl, _esxdos_semaphore
    inc (hl)
    pop hl
    ret



; ---------------------------------------------------------------------------

SECTION data_user

_esxdos_semaphore:
    defb 1 ; semaphore for ESXDOS calls


; Sound channel data structure
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

defc stereo_samples_pointer = mono_samples_channel + SC_CURSOR

stereo_samples_channel:
    defw stereo_samples_buffer & 0xFFFF         ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default

    defb -1                                     ; file handle
    defb (stereo_samples_buffer >> 8) & 0xFF    ; buffer area address (high byte)
    defb STEREO_BUFFER_SIZE >> 8                ; buffer size (high byte)
    defb 0                                      ; next buffer index 

defc mono_samples_pointer = mono_samples_channel + SC_CURSOR

mono_samples_channel:
    defw mono_samples_buffer & 0xFFFF           ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default

    defb -1                                     ; file handle 
    defb (mono_samples_buffer >> 8) & 0xFF      ; buffer area address (high byte)
    defb MONO_BUFFER_SIZE >> 8                  ; buffer size (high byte)
    defb 0                                      ; next buffer index


SECTION sound_data


