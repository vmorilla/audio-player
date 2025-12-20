#include <intrinsic.h>

#include "sound.h"
#include "zxn_ctc.h"

void set_sound_samples_interrupt_rate(uint8_t freqKHz)
{
    // CTC frequency = CPU frequency / ( prescaler(16) * ( 1 + time_constant ) )
    // Assuming CPU frequency set at 28MHz
    uint8_t time_constant = (28000 / (freqKHz * 16)) - 1;

    IO_CTC0 = 0b10000101;
    // No interrupt follows vector, Enable interrupt, Timer mode, Prescaler 16, Rising edge, Automatic trigger, Time constant follows, Continue operation, Control word
    IO_CTC0 = time_constant;

    // Interrup rate to check if a buffer needs to be loaded from disk
    IO_CTC1 = 0b10000101;
    IO_CTC1 = 255;
}
