SECTION code_user

PUBLIC __trace, __assert
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
