
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>

#include <arch/zxn.h>
#include <arch/zxn/esxdos.h>

#include "debug.h"
#include "interrupts.h"
#include "sound.h"

int main(void)
{
    zx_cls(PAPER_WHITE);
    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(32); // 32 kHz
    // if (play_sound_file("music/intro.raw") == -1)
    // {
    //     printf("Error loading sound file!");
    // }
    // else
    // {
    //     add_interrupt_handler(INT_CTC_CHANNEL_0, sound_interrupt_handler);
    // }

    while (1)
    {
        char key = in_inkey();
        // Avoid processing repeated keys
        if (key == 'i')
        {
            printf("Playing intro...\n");
            play_sound_file("music/intro.raw");
            in_wait_nokey();
        }
        if (key == 'l')
        {
            printf("Playing loop...\n");
            play_sound_file("music/loop.raw");
            in_wait_nokey();
        }
    }
}
