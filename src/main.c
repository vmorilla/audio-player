
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>

#include <arch/zxn.h>

#include "debug.h"
#include "interrupts.h"
#include "samples_counter.h"
#include "sound.h"

#define FREQ 16 // in kHz

void show_instructions(void)
{
    puts("\n\n\n\n");
    puts("'p' to pause sound\n");
    puts("'r' to resume sound\n");
    puts("'i' to play intro & loop\n");
    puts("'q' to queue outro\n");
    puts("'o' to play outro\n");
}

void read_commands(void)
{
    int key = in_inkey();
    if (key != 0)
    {
        switch (key)
        {
        case 'i':
            puts("Playing intro & loop...\n");
            play_stereo_sound_file("music/intro.raw", false);
            queue_stereo_sound_file("music/loop.raw", true);
            break;
        case 'q':
            puts("Queuing outro...\n");
            queue_stereo_sound_file("music/outro.raw", false);
            break;
        case 'o':
            puts("Playing outro...\n");
            play_stereo_sound_file("music/outro.raw", false);
            break;
        case 'p':
            puts("Pause sound...\n");
            pause_sound();
            break;
        case 'r':
            puts("Resuming sound...\n");
            start_sound();
            break;
        }
        in_wait_nokey();
    }
}

int main(void)
{
    zx_cls(PAPER_WHITE);
    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(FREQ);

    show_instructions();

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
    }
}
