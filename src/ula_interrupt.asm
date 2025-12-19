SECTION code_user

PUBLIC _ula_interrupt_handler

EXTERN _sound_loader_handler


_ula_interrupt_handler:
    ; Does not seem to be needed
	NEXTREG $C8, %00000001

    ; interruptions should be enabled asap to enable CTC interruptions in the middle 
    ei

    ;call _sound_loader_handler

    reti

SECTION data_user

_frame_counter:
    defb 0