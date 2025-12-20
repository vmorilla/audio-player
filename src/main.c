
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>

#include <arch/zxn/esxdos.h>

#include "debug.h"
#include "interrupts.h"
#include "sound.h"
#include "zxn.h"

int main(void)
{
    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(16); // 16 kHz
    if (play_sound_file("music/intro.raw") == -1)
    {
        printf("Error loading sound file!");
    }

    while (1)
    {
        intrinsic_halt();
    }
}
