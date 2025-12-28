
#include <input.h>
#include <intrinsic.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <arch/zxn.h>

#include "debug.h"
#include "interrupts.h"
#include "samples_counter.h"
#include "sound.h"

#define SCREEN_EXT_WIDTH 320
#define SCREEN_EXT_HEIGHT 256

void load_palette(char *palette_data)
{
    ZXN_NEXTREG(0x43, 0b00010000); // Auto increment, Layer 2 first palette for read/write
    ZXN_NEXTREG(0x40, 0);          // Start copying into index 0
                                   // Sets the transparency index

    for (uint16_t i = 0; i < 256; i++)
    {
        ZXN_NEXTREGA(0x41, palette_data[i]);
    }
}

void clip_tilemap_window(uint8_t x1, uint8_t x2, uint8_t y1, uint8_t y2)
{
    ZXN_NEXTREGA(REG_CLIP_WINDOW_CONTROL, RCWC_RESET_TILEMAP_CLIP_INDEX | RCWC_RESET_ULA_CLIP_INDEX);
    ZXN_NEXTREGA(REG_CLIP_WINDOW_TILEMAP, x1);
    ZXN_NEXTREGA(REG_CLIP_WINDOW_TILEMAP, x2);
    ZXN_NEXTREGA(REG_CLIP_WINDOW_TILEMAP, y1);
    ZXN_NEXTREGA(REG_CLIP_WINDOW_TILEMAP, y2);
}

void tilemap_mode(void)
{
#define START_OF_BANK_5 0x4000
#define START_OF_TILEMAP 0x6000 // Just after ULA attributes and system vars
#define START_OF_TILES 0x6600   // Just after
#define OFFSET_OF_MAP ((START_OF_TILEMAP - START_OF_BANK_5) >> 8)
#define OFFSET_OF_TILES ((START_OF_TILES - START_OF_BANK_5) >> 8)

    ZXN_NEXTREG(0x6B, 0b11100001); // 80x32, 8-bit entries
    ZXN_NEXTREG(0x6C, 0b00000000); // palette offset, visuals
    ZXN_NEXTREG(REG_TILEMAP_TRANSPARENCY_INDEX, 0x00);

    memset((void *)START_OF_TILEMAP, 0x20, 80 * 32); // Clear bank 5

    ZXN_NEXTREGA(0x6E, OFFSET_OF_MAP);
    ZXN_NEXTREGA(0x6F, OFFSET_OF_TILES);

    clip_tilemap_window(0, (uint8_t)(SCREEN_EXT_WIDTH / 2 - 1), 0, (uint8_t)(SCREEN_EXT_HEIGHT - 1));
}

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
    static int last_key;

    int new_key = in_inkey();

    if (new_key != last_key)
    {
        last_key = new_key;

        switch (new_key)
        {
        case 'i':
            // puts("Playing intro & loop...\n");
            play_sound_file(STEREO_CHANNEL, "music/stereo_channel.raw");
            // queue_sound_file(STEREO_CHANNEL, "music/loop.raw", true);
            break;

        case 'q':
            // puts("Queuing outro...\n");
            // queue_sound_file(STEREO_CHANNEL, "music/outro.raw");
            break;

        case 'o':
            // puts("Playing outro...\n");
            play_sound_file(STEREO_CHANNEL, "music/outro.raw");
            break;

        case 'p':
            // puts(stereo_channel_paused ? "Resume sound...\n" : "Pause sound...\n");
            // stereo_channel_paused = !stereo_channel_paused;
            break;

        case 's':
            // puts("Mono channel...\n");
            // puts("\x16\x01\x15.               \n");
            play_sound_file(MONO_CHANNEL, "music/scream.raw");
            break;
        }
    }
}

void post_scream(void)
{
    puts("\x16\x01\x15Scream finished!\n");
}

int main(void)
{
    zx_cls(PAPER_WHITE);
    ZXN_NEXTREGA(REG_PERIPHERAL_3, ZXN_READ_REG(REG_PERIPHERAL_3) | RP3_DISABLE_CONTENTION);

    tilemap_mode();

    show_instructions();

    hardware_interrupt_mode();
    set_sound_samples_interrupt_rate(8); // 16 kHz

    // mono_channel_callback = post_scream;

    uint8_t n = 0;
    uint16_t total = 0;
    uint16_t average = 0;

    while (1)
    {
        // printf("\x16\x01\x01Rate: %u Hz      \n", sound_samples_played * 25);
        // printf("Average: %u Hz        \n", average * 25);
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
