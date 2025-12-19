
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>

#include <arch/zxn/esxdos.h>

#include "debug.h"
#include "interrupts.h"
#include "sound.h"
#include "zxn.h"

int main(void)
{
    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(16); // 16 kHz
    play_sound_file("music/intro.raw");

    // uint8_t current_mmu6_bank = ZXN_READ_MMU6();
    // ZXN_WRITE_MMU6(0x50); // switch to bank 0 to fill the buffer

    // for (int i = 0; i < 512; i++)
    // {
    //     SOUND_SAMPLES_BUFFER[0][i] = i & 0xFF;
    // }

    // ZXN_WRITE_MMU6(current_mmu6_bank);

    // empty_buffers_mask = 0; // both buffers full

    while (1)
    {
        intrinsic_halt();
    }
}
