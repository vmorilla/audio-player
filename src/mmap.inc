; Memory map defintion
; First is the section name, which includes the prefix  BANK_N or PAGE_N plus as an optional suffix
; Followed by the ORG directive and followed by an alias section name



; Code common to all banks (libraries, main loop, etc...). Always mapped in 0x8000 - 0xBFFF
; This is the default bank... I think we don't need to be explicit
; SECTION BANK_2_CODE ; Pages 4 and 5
;     ORG 0x048000 ; 0x8000 - 0xBFFF
; SECTION common_code                                

; Code for the game itself
SECTION BANK_8_CODE ; Pages 16 and 17
    ORG 0x100000 ; 0x0000 - 0x3FFF
section game_code
section game_const

SECTION BANK_48_CODE  ; Pages 96 and 97
    ORG 0x600000 ; 0x0000 - 0x3FFF
section init_code
section init_const 
section menu_code
section menu_const

SECTION BANK_35_CODE    ; Pages 70 and 71
    ORG 0x460000 ; 0x0000 - 0x3FFF
section players_code
section players_const



SECTION BANK_0_DATA_DYNAMIC
    ORG 0xFB00
section sprite_definition_table          ; Skin definitions occupy approximately 200 bytes

SECTION BANK_0_CODE_INTERRUP_VECTOR_TABLE
    ORG 0xFC00
section code_interrupt_vector_table


