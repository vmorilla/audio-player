
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <arch/zxn.h>

#include "interrupts.h"
#include "samples_counter.h"
#include "sound.h"

void show_instructions(void)
{
    puts("\n\n\n\n");
    puts("'s' stereo play\n");
    puts("'m' mono play\n");
}

void read_commands(void)
{
    static int last_key;

    int new_key = in_inkey();

    if (new_key != last_key)
    {
        last_key = new_key;

        switch (new_key)
        {
        case 's':
            play_sound_file(STEREO_CHANNEL, "music/stereo.raw");
            break;

        case 'm':
            play_sound_file(MONO_CHANNEL, "music/mono.raw");
            break;
        }
    }
}

int main(void)
{
    zx_cls(PAPER_WHITE);
    ZXN_NEXTREGA(REG_PERIPHERAL_3, ZXN_READ_REG(REG_PERIPHERAL_3) | RP3_DISABLE_CONTENTION);

    show_instructions();

    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(16); // 16 kHz

    uint8_t n = 0;
    uint16_t total = 0;
    uint16_t average = 0;

    while (1)
    {
        printf("\x16\x01\x01Rate: %u Hz      \n", sound_samples_played * 25);
        printf("Average: %u Hz        \n", average * 25);

        read_commands();
        n++;
        total += sound_samples_played;
        if (n == 50)
        {
            average = total / 50;
            n = 0;
            total = 0;
        }

        update_sound_channels();
        intrinsic_halt();
    }
}
