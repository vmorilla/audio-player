; This can be used to append the content of a mmap.inc file; however, it only admits newly defined sections.
; For redefining existing ones, we must use #pragma output CRT_ORG_PAGE_XX = 0xYYYY
; However, if we add a suffix, it is possible to redefine in MMAP

; No malloc calls in the code
#pragma output CLIB_MALLOC_HEAP_SIZE = 0

; Append custom banks (defined in mmap.inc)
#pragma output CRT_APPEND_MMAP = 1

; Banked calls configure to use MMU 0 and 1
#pragma output CLIB_BANKING_SEGMENT = 0

; Additional RAM for code in ROM area
;#pragma output CRT_ORG_BANK_8 = 0x0000

; Layer 2 pages: 18 - 27, 28 - 37

; Redefines the default memory map for sprite pages
#pragma output CRT_ORG_PAGE_38 = 0xc000
#pragma output CRT_ORG_PAGE_39 = 0xc000
#pragma output CRT_ORG_PAGE_40 = 0xc000
#pragma output CRT_ORG_PAGE_41 = 0xc000
#pragma output CRT_ORG_PAGE_42 = 0xc000
#pragma output CRT_ORG_PAGE_43 = 0xc000
#pragma output CRT_ORG_PAGE_44 = 0xc000
#pragma output CRT_ORG_PAGE_45 = 0xc000
#pragma output CRT_ORG_PAGE_46 = 0xc000
#pragma output CRT_ORG_PAGE_47 = 0xc000
#pragma output CRT_ORG_PAGE_48 = 0xc000
#pragma output CRT_ORG_PAGE_49 = 0xc000
#pragma output CRT_ORG_PAGE_50 = 0xc000
#pragma output CRT_ORG_PAGE_51 = 0xc000
#pragma output CRT_ORG_PAGE_52 = 0xc000
#pragma output CRT_ORG_PAGE_53 = 0xc000
#pragma output CRT_ORG_PAGE_54 = 0xc000
#pragma output CRT_ORG_PAGE_55 = 0xc000
#pragma output CRT_ORG_PAGE_56 = 0xc000
#pragma output CRT_ORG_PAGE_57 = 0xc000
#pragma output CRT_ORG_PAGE_58 = 0xc000
#pragma output CRT_ORG_PAGE_59 = 0xc000
#pragma output CRT_ORG_PAGE_60 = 0xc000
#pragma output CRT_ORG_PAGE_61 = 0xc000
#pragma output CRT_ORG_PAGE_62 = 0xc000
#pragma output CRT_ORG_PAGE_63 = 0xc000
#pragma output CRT_ORG_PAGE_64 = 0xc000
#pragma output CRT_ORG_PAGE_65 = 0xc000
#pragma output CRT_ORG_PAGE_66 = 0xc000
#pragma output CRT_ORG_PAGE_67 = 0xc000
#pragma output CRT_ORG_PAGE_68 = 0xc000
#pragma output CRT_ORG_PAGE_69 = 0xc000
; For the moment, the top loaded page is 52

; Pages 70 and 71 for code extensions



; Page 94 is used by the DeZog debugger in the next.... avoid

; Redefines the default memory map for arkos player code
;#pragma output CRT_ORG_PAGE_94 = 0xc000


; Defines the default memory map for the intro song tracks
; #pragma output CRT_ORG_PAGE_95 = 0x0000.  <--- This caused problems when mixed with esx calls
#pragma output CRT_ORG_PAGE_95 = 0x6000

; Menu pages 96 - 97
; #pragma output CRT_ORG_PAGE_96 = 0x0000


; Redefines the default memory map for the fadeout effect data
#pragma output CRT_ORG_PAGE_98 = 0xc000

; Redefines the default memory map for tilemap pages
#pragma output CRT_ORG_PAGE_99 = 0xc000

; Redefines the default memory map for sounds (PAGE 100 and onwards)
; are not necessary since explicitly defined in the corresponding .asm file


; CURRENTLY REACHING PAGE 151 -> it can be extended up to 223