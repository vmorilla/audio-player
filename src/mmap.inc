; Memory map defintion
; First is the section name, which includes the prefix  BANK_N or PAGE_N plus as an optional suffix
; Followed by the ORG directive and followed by alias section names

; Example:
; SECTION BANK_8_CODE ; Pages 16 and 17
;     ORG 0x100000 ; 0x0000 - 0x3FFF
; section game_code
; section game_const



SECTION BANK_0_CODE_INTERRUP_VECTOR_TABLE
    ORG 0xFC00
section code_interrupt_vector_table


