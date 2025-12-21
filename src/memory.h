#ifndef _MEMORY_H_
#define _MEMORY_H_

/**
 * Functions to facilitate memory management operations
 */

#include <arch/zxn.h>

/**
 * Macro to call a function that makes usage of ROM calls
 */
#define ROM_BANKED_CALL(fn)      \
    __asm__("call banked_call"); \
    __asm__("dw _" #fn);         \
    __asm__("dw 0xff");          \
    __asm__("ret")

uint8_t read_nextreg(uint8_t reg) __z88dk_fastcall;
void set_mmu_data_page(uint8_t value) __z88dk_fastcall;
void restore_mmu_data_page(void);

#endif /* _MEMORY_H_ */