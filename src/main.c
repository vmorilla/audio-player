
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>

#include <arch/zxn.h>
#include <arch/zxn/esxdos.h>

#include "debug.h"
#include "interrupts.h"
#include "sound.h"

#define FREQ 16 // in kHz

int main(void)
{
    zx_cls(PAPER_WHITE);
    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(FREQ);

    printf("'i' to play intro\n'l' to play loop\n's' to stop sound\n");

    while (1)
    {
        in_wait_key();
        switch (in_inkey())
        {
        case 'i':
            printf("Playing intro...\n");
            play_sound_file("music/intro.raw", false);
            break;

        case 'l':
            printf("Playing loop...\n");
            play_sound_file("music/loop.raw", true);
            break;

        case 's':
            printf("Stopping sound...\n");
            stop_sound();
            break;
        }
        in_wait_nokey();
    }
}
