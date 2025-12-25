SECTION code_user

INCLUDE "macros.inc"
INCLUDE "zxn_constants.h"
INCLUDE "config_zxn_private.inc"

PUBLIC _hardware_interrupt_mode

EXTERN read_nextreg_di
EXTERN samples_counter_interrupt_handler, sound_interrupt_handler


; Important.... init sound must be called after setting the hardware interrupt mode...
; CTC interruptions are happending despite the corresponding register is set to 0

_hardware_interrupt_mode:
    di
    ; ** Quite important is that you should be changing nextreg 0xc0 with a read-modify-write operation.  
    ; That's because starting in nextzxos versions for core 3.01.10, nextzxos operates in the stackless nmi mode 
    ; which is controlled by bit 3. (see https://discord.com/channels/556228195767156758/692885312296190102/894284968614854749)

    ld a, REG_INTERRUPT_CONTROL
    ld bc, __IO_NEXTREG_REG
    out (c), a
    inc c
    in a, (c)
    and %00011110
    or (interrupt_vector_table & %11100000) | %00000001    
    nextreg REG_INTERRUPT_CONTROL, a
    nextreg REG_INTERRUPT_ENABLE_0, %00000010 ; Enable line and disables expansion bus interrupts
    nextreg REG_INTERRUPT_ENABLE_1, 1 ; enable CTC channel 0 interrupt
    nextreg REG_INTERRUPT_ENABLE_2, 0

	nextreg REG_INTERRUPT_STATUS_0, $FF ; 
	nextreg REG_INTERRUPT_STATUS_1, $FF ; Set status bits to clear
	nextreg REG_INTERRUPT_STATUS_2, $FF ; 

    nextreg REG_DMA_INTERRUPT_ENABLE_0,0x02
    ; Enabling DMA interrupts does not seem to cause any harm
	nextreg REG_DMA_INTERRUPT_ENABLE_1,0x01
	;nextreg REG_DMA_INTERRUPT_ENABLE_1,0xff
	nextreg REG_DMA_INTERRUPT_ENABLE_2,0 

    ld a, interrupt_vector_table >> 8
    ld i, a
    im 2 ; enable HW Interrupt Mode 2
    ei
    ret

default_interrupt_handler:
    ei
    reti

SECTION code_interrupt_vector_table

interrupt_vector_table:
    defw samples_counter_interrupt_handler ; 0: line interrupt
    defw default_interrupt_handler ; 1: UART0 RX
    defw default_interrupt_handler ; 2: UART1 RX
    defw sound_interrupt_handler ; 3: CTC channel 0
    defw default_interrupt_handler ; 4: CTC channel 1
    defw default_interrupt_handler ; 5: CTC channel 2
    defw default_interrupt_handler ; 6: CTC channel 3
    defw default_interrupt_handler ; 7: CTC channel 4
    defw default_interrupt_handler ; 8: CTC channel 5
    defw default_interrupt_handler ; 9: CTC channel 6
    defw default_interrupt_handler ; 10: CTC channel 7
    defw default_interrupt_handler ; 11: ULA interrupt
    defw default_interrupt_handler ; 12: UART0 TX
    defw default_interrupt_handler ; 13: UART1 TX
    defw default_interrupt_handler ; 14: Not documented
    defw default_interrupt_handler ; 15: Not documented


