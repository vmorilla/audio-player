SECTION BANK_5_CODE

; The tile definition starts in the space character (32). Each tile is 32 bytes
ORG 0x6600 + 32 * 32

INCBIN "../build/tiles/envious_serif.td"