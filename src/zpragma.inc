; This can be used to append the content of a mmap.inc file; however, it only admits newly defined sections.
; For redefining existing ones, we must use #pragma output CRT_ORG_PAGE_XX = 0xYYYY
; However, if we add a suffix, it is possible to redefine in MMAP

; No malloc calls in the code
#pragma output CLIB_MALLOC_HEAP_SIZE = 0

; Append custom banks (defined in mmap.inc)
#pragma output CRT_APPEND_MMAP = 1

; Banked calls configure to use MMU 0 and 1
#pragma output CLIB_BANKING_SEGMENT = 0

