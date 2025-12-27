#include <intrinsic.h>
#include <arch/zxn.h>
#include <stdbool.h>
#include "interrupts.h"
#include "sound.h"
#include "zxn_ctc.h"

// typedef struct
// {
//     volatile bool paused;               // 1 = paused, 0 = playing
//     volatile char *cursor;              // current cursor in the buffer
//     volatile int8_t file_handle;        // file handle associated to the channel
//     volatile int8_t queued_file_handle; // queued file handle to be played when the current one ends
//     volatile bool loop_mode;            // loop mode (0 = no loop, 1 = loop)
//     const char *buffer_area;            // buffer address (low part)
//     const uint16_t buffer_area_size;    // buffer size in bytes
//     void (*callback)(void);             // callback function when the sound ends
// } SoundChannel;

void set_sound_samples_interrupt_rate(uint8_t freqKHz)
{
    // CTC frequency = CPU frequency / ( prescaler(16) * ( 1 + time_constant ) )
    // Rearranged:
    // time_constant = CTC frequency / (CPU frequeny *
    // Assuming CPU frequency set at 28MHz
    uint8_t time_constant = (28000 / (freqKHz * 16)) - 1;

    IO_CTC0 = 0b10000101;
    // No interrupt follows vector, Enable interrupt, Timer mode, Prescaler 16, Rising edge, Automatic trigger, Time constant follows, Continue operation, Control word
    IO_CTC0 = time_constant;
}
