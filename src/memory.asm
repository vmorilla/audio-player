SECTION code_user



PUBLIC _read_nextreg, _set_mmu_data_page, _restore_mmu_data_page

; The alternative asm versions do not modify the interrupt state (disabled interruptions are assumed)
PUBLIC set_mmu_data_page_di, restore_mmu_data_page_di, read_nextreg_di

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

read_nextreg_di:
    ld bc, __IO_NEXTREG_REG
    out (c), a
    inc c
    in a, (c)
    ret

; void set_mmu_data_page(uint8_t value) __z88dk_fastcall;
; new page in L
; modifies hl, af
_set_mmu_data_page:
    di
    ld a, l
    call set_mmu_data_page_di
    ei
    ret

set_mmu_data_page_di:
    ld hl, (datammu_stack_pointer)
    dec hl
    ld (datammu_stack_pointer), hl
    ld (hl), a
    nextreg __REG_MMU6, a
    ret

; void restore_mmu_data_page(void);
; restores previous MMU data page
; modifies hl, af
; returns in A the restored page
_restore_mmu_data_page:
    di
    call restore_mmu_data_page_di
    ei
    ret

restore_mmu_data_page_di:
    ld hl, (datammu_stack_pointer)
    inc hl
    ld (datammu_stack_pointer), hl
    ld a, (hl)
    nextreg __REG_MMU6, a
    ret



SECTION data_user

; Stack area to store previous MMU data page values. We don't expect more than 2 or 3 nested calls
datammu_stack: 
    defs 16, 0
datammu_stack_end:

; Pointer in the stack to previous MMU data page values
datammu_stack_pointer: 
    defw datammu_stack_end - 1

