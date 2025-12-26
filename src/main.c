
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>

#include <arch/zxn.h>

#include "debug.h"
#include "interrupts.h"
#include "samples_counter.h"
#include "sound.h"

void show_instructions(void)
{
    puts("\n\n\n\n");
    puts("'p' to pause / resume\n");
    puts("'i' to play intro & loop\n");
    puts("'q' to queue outro\n");
    puts("'o' to play outro\n");
    puts("'s' to play a scream (mono)\n");
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
            play_sound_file(STEREO_CHANNEL, "music/stereo_channel.raw", false);
            // queue_sound_file(STEREO_CHANNEL, "music/loop.raw", true);
            break;

        case 'q':
            puts("Queuing outro...\n");
            queue_sound_file(STEREO_CHANNEL, "music/outro.raw", false);
            break;

        case 'o':
            puts("Playing outro...\n");
            play_sound_file(STEREO_CHANNEL, "music/outro.raw", false);
            break;

        case 'p':
            puts(stereo_channel_paused ? "Resume sound...\n" : "Pause sound...\n");
            stereo_channel_paused = !stereo_channel_paused;
            break;

        case 's':
            puts("Mono channel...\n");
            puts("\x16\x01\x15.               \n");
            play_sound_file(MONO_CHANNEL, "music/scream.raw", false);
            break;
        }
        in_wait_nokey();
    }
}

void post_scream(void)
{
    puts("\x16\x01\x15Scream finished!\n");
}

int main(void)
{
    zx_cls(PAPER_WHITE);
    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(16); // 16 kHz

    // mono_channel_callback = post_scream;

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
