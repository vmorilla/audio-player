SECTION code_user

PUBLIC __trace, __assert, __tile_trace_line, __tile_trace_int, __tile_trace_short, __tile_trace_char

; --------------------------------------------------------------
; void _trace(const char *message, ...);
; after ix = sp + 4
; ix + 0 = string message, ended with 0
; ix + 2 = first argument...
; --------------------------------------------------------------
__trace:
    push ix
    ld ix, 4
    add ix, sp
    call trace_common_entry
    pop ix
    ret

trace_common_entry:
    ld bc, $8080  ; Port logger is listening to this port
    out (c), 0 ; Activate trace via selected port. Logic has been moved to the CSpect plugin.
    ret

; --------------------------------------------------------------


; --------------------------------------------------------------
; void _assert(bool condition, const char *message, ...);
; after ix = sp + 5
; ix - 1 = condition
; ix + 0 = string message, ended with 0
; ix + 2 = first argument...
; --------------------------------------------------------------

__assert:
    push ix
    ld ix, 5
    add ix, sp
    ld a, (ix - 1)
    or a
    jr nz, exit_assert
    call trace_common_entry
    ; cspect break
    defb 0xfd, 0x00
exit_assert:
    pop ix
    ret



; --------------------------------------------------------------
; trace function on tile map screen
; void _tile_trace_line(uint8_t line) __z88dk_fastcall;
; A: line number
; --------------------------------------------------------------
__tile_trace_line:
    ld e, a
    ld d, 80
    mul de
    ld hl, 0x4000
    add hl, de
    ld (cursor), hl
    ret

; --------------------------------------------------------------
; trace function on tile map screen
; void _title_trace_number(uint16_t number) __z88dk_fastcall;
; HL: number
; --------------------------------------------------------------

__tile_trace_int:
    ld a, h
    call __tile_trace_short
    ld a, l
    jp __tile_trace_short

__tile_trace_short:
    ld c, a
    swapnib
    call __tile_trace_digit
    ld a, c
    jp __tile_trace_digit

__tile_trace_digit:
    and $0f
    add a, '0'
    cp '9' + 1
    jr c, __tile_trace_char
    add a, 'A' - '9' - 1

; --------------------------------------------------------------
; draw a character at cursor position and increase the cursor
__tile_trace_char:
    ld de, (cursor)
    ld (de), a
    inc de
    inc de
    ld (cursor), de
    ret



SECTION data_user

cursor:
    defw 0x4000