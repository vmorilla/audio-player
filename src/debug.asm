SECTION code_user

PUBLIC __trace, __assert, __trace_registers
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

_tilemap_scroll:
    push af
    push bc
    push de
    push hl

    ld b, 31
    ld hl, tilemap_base_address + 80
    ld de, tilemap_base_address
_tilemap_scroll_next_line:
    ld bc, 80 * 31
    ldir
    ld hl, de
    ld (trace_cursor), hl
    ld (hl), ' '
    inc de
    ld bc, 79
    ldir

    pop hl
    pop de
    pop bc
    pop af
    ret

_trace_hl:
    ld a, h
    ld de, (trace_cursor)
    and 0xF0
    swapnib
    call _trace_digit
    ld a, h
    and 0x0F
    call _trace_digit
    ld a, l
    and 0xF0
    swapnib
    call _trace_digit
    ld a, l
    and 0x0F
    call _trace_digit
    ret

_trace_string:
    ex (sp), hl
    call _trace_string_hl
    ex (sp), hl
    ret

_trace_string_hl:
    ld de, (trace_cursor)
__next_char:
    ld a, (hl)
    inc hl
    and a
    jr z, __end_string
    ld (de), a
    inc de
    jr __next_char
__end_string:
    ld (trace_cursor), de
    ret

_trace_digit:
    ld de, (trace_cursor)
    add a, '0'
    cp '9' + 1
    jr c, __is_digit
    add a, 7
__is_digit:
    ld (de), a
    inc de
    ld (trace_cursor), de
    ret


__trace_registers:
    call _tilemap_scroll
    ex (sp), hl

    push af
    push bc
    push de
    call _trace_string_hl
    push hl

    push hl
    push de
    push bc
    push af

    call _trace_string
    defb "AF: \0"
    pop hl
    call _trace_hl
    call _trace_string
    defb " - BC: \0"    
    pop hl
    call _trace_hl
    call _trace_string
    defb " - DE: \0"    
    pop hl
    call _trace_hl
    call _trace_string
    defb " - HL: \0"    
    pop hl
    call _trace_hl
    call _trace_string
    defb " - IX: \0"
    push ix
    pop hl
    call _trace_hl
    call _trace_string
    defb " - IY: \0"
    push iy
    pop hl
    call _trace_hl
    call _trace_string
    defb " - SP: \0"
    ld hl, 0
    add hl, sp
    call _trace_hl

    pop hl
    pop de
    pop bc
    pop af

    ex (sp), hl
    ret


defc tilemap_base_address = 0x6000
defc tilemap_trace_address = 0x6000 + 25 * 80 + 10
defc tilemap_last_line = tilemap_base_address + 31 * 80


SECTION data_user
trace_cursor:
    defw tilemap_last_line