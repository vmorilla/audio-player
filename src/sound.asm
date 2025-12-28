
SECTION code_user

INCLUDE "config_zxn_private.inc"
INCLUDE "zxn_constants.h"

PUBLIC mono_samples_pointer, stereo_samples_pointer, sound_interrupt_handler
PUBLIC _play_sound_file, _queue_sound_file 
PUBLIC STEREO_BUFFER_SIZE

EXTERN set_mmu_data_page_di, restore_mmu_data_page_di, _set_mmu_data_page, _restore_mmu_data_page
EXTERN __trace_registers

defc STERO_BUFFER_SIZE_BITS = 10 ; 11 bits -> 2048 bytes stereo buffer, 10 bits -> 1024 bytes stereo buffer
defc STEREO_BUFFER_SIZE = 2 ** STERO_BUFFER_SIZE_BITS
defc STEREO_BUFFER_H_MASK = (STEREO_BUFFER_SIZE - 1) >> 8
defc STEREO_BUFFER_H_OVERFLOW_BIT = STERO_BUFFER_SIZE_BITS - 8
defc STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT = STEREO_BUFFER_H_OVERFLOW_BIT + 1

defc MONO_BUFFER_SIZE_BITS = STERO_BUFFER_SIZE_BITS - 1 ; Mono buffer is half the size of stereo buffer
defc MONO_BUFFER_SIZE = 2 ** MONO_BUFFER_SIZE_BITS
defc MONO_BUFFER_H_MASK = (MONO_BUFFER_SIZE - 1) >> 8
defc MONO_BUFFER_H_OVERFLOW_BIT = MONO_BUFFER_SIZE_BITS - 8
defc MONO_DOUBLE_BUFFER_H_OVERFLOW_BIT = MONO_BUFFER_H_OVERFLOW_BIT + 1

defc SOUND_EOF_MARKER = 0xFF


sound_interrupt_handler:
    push af
    push hl

    ld a, stereo_samples_buffer >> 16
    call set_mmu_data_page_di

    call process_stereo_sound_channel
    call process_mono_sound_channel

    call restore_mmu_data_page_di

    pop hl
    pop af
    ei
    reti

process_stereo_sound_channel:
    ; returns if buffers are empty
    ld a, (stereo_samples_channel + SC_REMAINING_BUFFERS)
    and a
    ret z

    ld hl, (stereo_samples_channel + SC_CURSOR)
    ld a, (hl)
    cp SOUND_EOF_MARKER         ; Check for end-of-buffer marker
    jr nz, stereo_output_sample
    
    xor a
    ld (stereo_samples_channel + SC_REMAINING_BUFFERS), a
    ret

stereo_output_sample:
    nextreg REG_DAC_LEFT, a
    inc hl
    ld a, (hl)
    nextreg REG_DAC_RIGHT, a
    inc hl

    res STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (stereo_samples_channel + SC_CURSOR), hl

    ld a, h
    and STEREO_BUFFER_H_MASK
    or l
    ret nz

    ; End of buffer reached
    ld hl, stereo_samples_channel + SC_REMAINING_BUFFERS
    dec (hl)
    ret

process_mono_sound_channel:
    ; returns if both buffers are empty
    ld a, (mono_samples_channel + SC_REMAINING_BUFFERS)
    and a
    ret z

    ld hl, (mono_samples_channel + SC_CURSOR)
    ld a, (hl)
    cp SOUND_EOF_MARKER         ; Check for end-of-buffer marker
    jr nz, mono_output_sample
    
    xor a
    ld (mono_samples_channel + SC_REMAINING_BUFFERS), a
    ret

mono_output_sample:
    nextreg REG_DAC_MONO, a
    inc hl

    res MONO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (mono_samples_channel + SC_CURSOR), hl

    ld a, h
    and MONO_BUFFER_H_MASK
    or l
    ret nz

    ; End of buffer reached
    ld hl, mono_samples_channel + SC_REMAINING_BUFFERS
    dec (hl)
    ret


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
    call f_acquire_semaphore
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

    call __trace_registers
    defb "w: \0"

    push bc ; save current buffer position
    push ix ; save remaining bytes to fill
    ld ixl, 0   ; esx_seek_set
    ld bc, 0   ; bcde = offset 0
    ld de, 0
    rst __ESX_RST_SYS
    defb __ESX_F_SEEK
    pop ix ; restore buffer position
    pop bc ; restore bytes to fill

    call __trace_registers
    defb "W: \0"

    ret 

f_close:
    ; A = file handle

    call __trace_registers
    defb "c: \0"

    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE

    call __trace_registers
    defb "C: \0"

    ret


    ; Input: 
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
    call __trace_registers
    defb "r: \0"

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

    call __trace_registers
    defb "R: \0"

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
    SC_BUFFER_AREA           DS.B 1       ; buffer address (high byte)
    SC_BUFFER_SIZE           DS.B 1       ; buffer size (high byte = size / 256)
    SC_NEXT_BUFFER           DS.B 1       ; high part of next buffer address 
    SC_STRUCT_SIZE    
  } 

defc stereo_samples_pointer = mono_samples_channel + SC_CURSOR

stereo_samples_channel:
    defw stereo_samples_buffer & 0xFFFF         ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default

    defb -1                                     ; file handle
    defb (stereo_samples_buffer >> 8) & 0xFF    ; buffer address (high byte)
    defb STEREO_BUFFER_SIZE >> 8                ; buffer size (high byte)
    defb (stereo_samples_buffer >> 8) & 0xFF    ; next buffer address (high byte)

defc mono_samples_pointer = mono_samples_channel + SC_CURSOR

mono_samples_channel:
    defw mono_samples_buffer & 0xFFFF           ; current cursor in the buffer
    defb 0                                      ; remaining buffers, paused by default

    defb -1                                     ; file handle 
    defb (mono_samples_buffer >> 8) & 0xFF      ; buffer address (high byte)
    defb MONO_BUFFER_SIZE >> 8                  ; buffer size (high byte)
    defb (mono_samples_buffer >> 8) & 0xFF      ; next buffer address (high byte)


SECTION sound_data

stereo_samples_buffer: 
left_channel_samples_buffer:
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER

right_channel_samples_buffer:
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER

mono_samples_buffer: 
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER


