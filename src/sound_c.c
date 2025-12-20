#include <intrinsic.h>
#include <arch/zxn.h>
#include <stdbool.h>
#include "interrupts.h"
#include "sound.h"
#include "zxn_ctc.h"

static bool sound_on = false;

int8_t play_sound_file(const char *filename, bool loop)
{
    stop_sound();
    int8_t result = load_sound_file(filename, loop);
    if (result != -1)
    {
        start_sound();
    }
    return result;
}

void set_sound_samples_interrupt_rate(uint8_t freqKHz)
{
    // CTC frequency = CPU frequency / ( prescaler(16) * ( 1 + time_constant ) )
    // Assuming CPU frequency set at 28MHz
    uint8_t time_constant = (28000 / (freqKHz * 16)) - 1;

    IO_CTC0 = 0b10000101;
    // No interrupt follows vector, Enable interrupt, Timer mode, Prescaler 16, Rising edge, Automatic trigger, Time constant follows, Continue operation, Control word
    IO_CTC0 = time_constant;
}

void stop_sound(void)
{
    interrupt_vector_table[INT_CTC_CHANNEL_0] = default_interrupt_handler;
}

void start_sound(void)
{
    interrupt_vector_table[INT_CTC_CHANNEL_0] = sound_interrupt_handler;
}