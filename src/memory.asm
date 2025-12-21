SECTION code_user



PUBLIC _read_nextreg, _set_mmu_data_page, _restore_mmu_data_page

INCLUDE "config_zxn_private.inc"

; uint8_t read_nextreg(uint8_t reg) __z88dk_fastcall;
; Reads a Next register in L and returns its value in L
; Modifies b, c 
_read_nextreg:
    ld bc, __IO_NEXTREG_REG
    di
    out (c), l
    inc c
    in l, (c)
    ei
    ret


; void set_mmu_data_page(uint8_t value) __z88dk_fastcall;
; new page in L
; modifies de, af
_set_mmu_data_page:
    di
    ld a, (datammu_stack_pointer)
    dec a
    ld e, a
    ld d, datammu_stack >> 8
    ld (datammu_stack_pointer), a
    ld a, l
    ld (de), a
    nextreg __REG_MMU6, a
    ei
    ret

; void restore_mmu_data_page(void);
; restores previous MMU data page
; modifies de, af
; returns in A the restored page
_restore_mmu_data_page:
    di
    ld a, (datammu_stack_pointer)
    inc a
    ld e, a
    ld d, datammu_stack >> 8
    ld (datammu_stack_pointer), a
    ld a, (de)
    nextreg __REG_MMU6, a
    ei
    ret


SECTION data_user

ALIGN	16

; Stack area to store previous MMU data page values. We don't expect more than 2 or 3 nested calls
datammu_stack: 
    defs 16, 0
datammu_stack_end:

; Pointer in the stack to previous MMU data page values
datammu_stack_pointer: 
    defw datammu_stack_end - 1

