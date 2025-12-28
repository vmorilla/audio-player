#ifndef _SOUND_H_
#define _SOUND_H_

#include <stdint.h>

typedef enum
{
    STEREO_CHANNEL,
    MONO_CHANNEL,
    LEFT_CHANNEL,
    RIGHT_CHANNEL
} SoundChannelId;

// Plays a sound file on the specified channel
// Returns -1 if error, the file handle if OK
int8_t play_sound_file(SoundChannelId channel, const char *filename);

// Updates the buffer in the sound channels if needed. Should be called in the
// application main loop
void update_sound_channels(void);

/**
 * Sets the interrupt rate for sound samples generation in kHz
 */
void set_sound_samples_interrupt_rate(uint8_t freqKHz);

#endif