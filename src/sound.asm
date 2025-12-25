
SECTION code_user

INCLUDE "config_zxn_private.inc"
INCLUDE "zxn_constants.h"
INCLUDE "macros.inc"

EXPORT mono_samples_pointer
EXPORT stereo_samples_pointer
EXPORT sound_interrupt_handler
EXPORT play_stereo_sound_file
EXPORT play_mono_sound_file
EXPORT queue_stereo_sound_file
EXPORT queue_mono_sound_file
EXPORT stereo_channel_paused
EXPORT mono_channel_paused
EXPORT STEREO_BUFFER_SIZE

; PUBLIC _sound_interrupt_handler
; PUBLIC _stereo_samples_pointer, _stereo_channel_paused
; PUBLIC _mono_samples_pointer, _mono_channel_paused
; PUBLIC _play_stereo_sound_file, _play_mono_sound_file
; PUBLIC _queue_stereo_sound_file, _queue_mono_sound_file

; defc _sound_interrupt_handler = sound_interrupt_handler
; defc _stereo_samples_pointer = stereo_samples_pointer
; defc _stereo_channel_paused = stereo_channel_paused
; defc _mono_samples_pointer = mono_samples_pointer
; defc _mono_channel_paused = mono_channel_paused
; defc _play_stereo_sound_file = play_stereo_sound_file
; defc _play_mono_sound_file = play_mono_sound_file
; defc _queue_stereo_sound_file = queue_stereo_sound_file
; defc _queue_mono_sound_file = queue_mono_sound_file


EXTERN set_mmu_data_page_di, restore_mmu_data_page_di, _set_mmu_data_page, _restore_mmu_data_page

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

; Sound channel data structure
  DEFVARS 0               
  {
    SOUND_CHANNEL_PAUSED                DS.B 1       ; 1 = paused, 0 = playing
    SOUND_CHANNEL_CURSOR                DS.W 1       ; current cursor in the buffer
    SOUND_CHANNEL_FILE_HANDLE           DS.B 1       ; file handle associated to the channel
    SOUND_CHANNEL_QUEUED_FILE_HANDLE    DS.B 1       ; queued file handle to be played when the current one ends
    SOUND_CHANNEL_LOOP_MODE             DS.B 1       ; loop mode (0 = no loop, 1 = loop)
    SOUND_CHANNEL_BUFFER_AREA           DS.W 1       ; buffer address (low part)
    SOUND_CHANNEL_BUFFER_AREA_SIZE      DS.W 1       ; buffer size in bytes
    SOUND_CHANNEL_CALLBACK              DS.W 1       ; callback function when the sound ends 
    SOUND_CHANNEL_STRUCT_SIZE    
  }

sound_interrupt_handler:
    push af
    push hl

    ld a, stereo_samples_buffer >> 16
    call set_mmu_data_page_di

    ld a, (stereo_channel_paused)
    and a
    jr nz, mono_channel ; channel paused

    ld hl, (stereo_samples_pointer)
    ld a, (hl)
    cp SOUND_EOF_MARKER         ; Check for end-of-buffer marker 
    jr nz, stereo_output_sample

    ; Mute stereo channel and continue with mono channel
    ld a, 1
    ld (stereo_samples_channel + SOUND_CHANNEL_PAUSED), a
    jr mono_channel

stereo_output_sample:
    nextreg REG_DAC_LEFT, a
    inc hl
    ld a, (hl)
    nextreg REG_DAC_RIGHT, a
    inc hl
    ld a, h
    and STEREO_BUFFER_H_MASK
    or l
    jr z, end_of_stereo_buffer

    ld (stereo_samples_pointer), hl

mono_channel:
    ld a, (mono_channel_paused)
    and a
    jr nz, end_interrupt ; channel paused

    ld hl, (mono_samples_pointer)
    ld a, (hl)
    cp SOUND_EOF_MARKER         ; Check for end-of-buffer marker
    jr nz, mono_output_sample

    ; Mute mono channel
    ld a, 1
    ld (mono_channel_paused), a
    jr end_interrupt

mono_output_sample:
    nextreg REG_DAC_MONO, a
    inc hl
    ld a, h
    and MONO_BUFFER_H_MASK
    or l
    jr z, end_of_mono_buffer

    ld (mono_samples_pointer), hl

    ; Restores the currengt page in MMU 6
end_interrupt:
    call restore_mmu_data_page_di
    pop hl
    pop af
    ei
    reti

end_of_stereo_buffer:
    res STEREO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (stereo_samples_pointer), hl

    ; signals that the ISR is done and continues to update buffers
    push stereo_buffer_needs_update
    ei
    reti

end_of_mono_buffer:
    res MONO_DOUBLE_BUFFER_H_OVERFLOW_BIT, h ; This ensures that the pointer goes back to the start of the first buffer
    ld (mono_samples_pointer), hl

    ; signals that the ISR is done and continues to update buffers
    push mono_buffer_needs_update
    ei
    reti


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
    call sound_loader_read_buffer
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


; Loads data into the buffer pointed by IX and length indicated by BC from the file handle pointed by HL

; IY = channel data structure
; IX = buffer pointer
; BC = bytes to read
sound_loader_read_buffer:   
    ld a, (IY + SOUND_CHANNEL_FILE_HANDLE)
load_chunk:
    ; Input: IX = buffer pointer, BC = bytes to read, A = file handle
    call f_read
    ret z ; buffer complete. We did not reach EOF

    ; The buffer has not been completely filled (file reached EOF)
    bit 7, (IY + SOUND_CHANNEL_QUEUED_FILE_HANDLE)
    jr nz, check_loop_mode ; No queued file, check loop mode
    
    ; Queued file found, switch to it
    ; First close current handler
    ld a, (IY + SOUND_CHANNEL_FILE_HANDLE)
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE

    ld a, (IY + SOUND_CHANNEL_QUEUED_FILE_HANDLE)
    ld (IY + SOUND_CHANNEL_FILE_HANDLE), a
    ld (IY + SOUND_CHANNEL_QUEUED_FILE_HANDLE), -1
    jr load_chunk

check_loop_mode:
    bit 0, (IY + SOUND_CHANNEL_LOOP_MODE)
    jr z, nothing_more_to_read

    ld a, (iy + SOUND_CHANNEL_FILE_HANDLE)
    // Rewind...
    call f_rewind
    jr sound_loader_read_buffer

nothing_more_to_read:
    ; Mark end of buffer with 0xff
    ld a, SOUND_EOF_MARKER
    ld (ix), a
    ret

play_stereo_sound_file:
    push iy
    ld iy, stereo_samples_channel
    call play_sound_file_struct
    pop iy
    ret

play_mono_sound_file:
    push iy
    ld iy, mono_samples_channel
    call play_sound_file_struct
    pop iy
    ret

queue_stereo_sound_file:
    push iy
    ld iy, stereo_samples_channel
    call queue_sound_file_struct
    pop iy
    ret

queue_mono_sound_file:
    push iy
    ld iy, mono_samples_channel
    call queue_sound_file_struct
    pop iy
    ret

; int8_t load_sound_file(const char *filename, bool loop);

; Input:
; IY = pointer to sound channel data structure
; Parameters in stack:
;    const char * filename 
;    bool loop
play_sound_file_struct:
    push ix
    ld ix, 8
    add ix, sp

    ; Pauses the sound channel
    ld (iy + SOUND_CHANNEL_PAUSED), 1 ; pauses the channel

    ; Closes previous file if any
    ld a, (iy + SOUND_CHANNEL_FILE_HANDLE)
    cp -1
    call nz, f_close ; Close previous file if any

    ld a, (ix + 2) ; loop parameter
    ld (iy + SOUND_CHANNEL_LOOP_MODE), a
    ld hl, (ix + 0) ; filename parameter

    call f_open
    jr nc, file_exists
    ; There was an error opening the file
    ld (iy + SOUND_CHANNEL_FILE_HANDLE), -1
    ld l,a
    pop ix
    ret

file_exists:
    ld (iy + SOUND_CHANNEL_FILE_HANDLE), a

    ; Sets data page
    ld l, stereo_samples_buffer >> 16
    call _set_mmu_data_page

    ; Fills both buffers
    ld ix, (iy + SOUND_CHANNEL_BUFFER_AREA)
    ; sets the sample pointer to the start of the first buffer
    ld (iy + SOUND_CHANNEL_CURSOR), ix

    ld bc, (iy + SOUND_CHANNEL_BUFFER_AREA_SIZE)
    call sound_loader_read_buffer

    ; Enables the sound channel
    ld (iy + SOUND_CHANNEL_PAUSED), 0 ; resumes the channel

    ; Restores the currengt page in MMU 6
    call _restore_mmu_data_page
    ; Returns 0 = success
    ld l, 0
    pop ix
    ret

; int8_t load_sound_file(const char *filename, bool loop);
queue_sound_file_struct:
    push ix
    ; Closes previous file if any
    ld a, (iy + SOUND_CHANNEL_QUEUED_FILE_HANDLE)
    cp -1
    call nz, f_close ; Close previous file if any
    
    ld ix, 8
    add ix, sp
    ld a, (ix + 2) ; loop parameter
    ld (iy + SOUND_CHANNEL_LOOP_MODE), a
    ld hl, (ix + 0) ; filename parameter
    call f_open
    jr nc, queue_file_exists
    ; There was an error opening the file
    ld a, -1
queue_file_exists:
    ld (iy + SOUND_CHANNEL_QUEUED_FILE_HANDLE), a
    ld l,a
    pop ix
    ret

; ---------------------------------------------------------------------------


    ; ----------------------------------------------------------------------
    ; A = file handle
    ; Rewinds the file to the beginning
    ; IX and BC are preserved
    ; ----------------------------------------------------------------------
f_rewind:
    // Loop mode...
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

f_close:
    ; A = file handle
    rst __ESX_RST_SYS
    defb __ESX_F_CLOSE
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
    rst __ESX_RST_SYS
    defb __ESX_F_OPEN
    ret
    ; ----------------------------------------------------------------------



; ---------------------------------------------------------------------------

SECTION data_user

defc stereo_channel_paused = stereo_samples_channel + SOUND_CHANNEL_PAUSED
defc stereo_samples_pointer = stereo_samples_channel + SOUND_CHANNEL_CURSOR

    ; SOUND_CHANNEL_PAUSED                DS.B 1       ; 1 = paused, 0 = playing
    ; SOUND_CHANNEL_CURSOR                DS.W 1       ; current cursor in the buffer
    ; SOUND_CHANNEL_FILE_HANDLE           DS.B 1       ; file handle associated to the channel
    ; SOUND_CHANNEL_QUEUED_FILE_HANDLE    DS.B 1       ; queued file handle to be played when the current one ends
    ; SOUND_CHANNEL_LOOP_MODE             DS.B 1       ; loop mode (0 = no loop, 1 = loop)
    ; SOUND_CHANNEL_BUFFER_AREA           DS.W 1       ; buffer address (low part)
    ; SOUND_CHANNEL_BUFFER_AREA_SIZE      DS.W 1       ; buffer size in bytes
    ; SOUND_CHANNEL_CALLBACK              DS.W 1       ; callback function when the sound ends 
    ; SOUND_CHANNEL_STRUCT_SIZE    

stereo_samples_channel:
    defb 1                                  ; paused by default
    defw stereo_samples_buffer & 0xFFFF    ; current cursor in the buffer
    defb -1                                 ; file handle being played
    defb -1                                 ; queued file handle to be played when the current one ends
    defb 0                                  ; loop mode (0 = no loop, 1 = loop)
    defw stereo_samples_buffer & 0xFFFF    ; buffer address 
    defw STEREO_BUFFER_SIZE * 2             ; buffer area size 
    defw 0                                  ; callback function when the sound ends  

defc mono_channel_paused = mono_samples_channel + SOUND_CHANNEL_PAUSED   
defc mono_samples_pointer = mono_samples_channel + SOUND_CHANNEL_CURSOR

mono_samples_channel:
    defb 1                                  ; paused by default
    defw mono_samples_buffer & 0xFFFF    ; current cursor in the buffer
    defb -1                                 ; file handle being played
    defb -1                                 ; queued file handle to be played when the current one ends
    defb 0                                  ; loop mode (0 = no loop, 1 = loop)
    defw mono_samples_buffer & 0xFFFF    ; buffer address 
    defw MONO_BUFFER_SIZE * 2             ; buffer area size 

SECTION sound_data

stereo_samples_buffer: 
    defs STEREO_BUFFER_SIZE * 2, SOUND_EOF_MARKER

mono_samples_buffer: 
    defs STEREO_BUFFER_SIZE, SOUND_EOF_MARKER