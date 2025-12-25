#ifndef _SOUND_H_
#define _SOUND_H_

#include <stdint.h>

int8_t play_stereo_sound_file(const char *filename, bool loop);
int8_t queue_stereo_sound_file(const char *filename, bool loop);
int8_t play_mono_sound_file(const char *filename, bool loop);
int8_t queue_mono_sound_file(const char *filename, bool loop);

void start_sound(void);
void pause_sound(void);

void sound_interrupt_handler(void);

/**
 * Sets the interrupt rate for sound samples generation in kHz
 */
void set_sound_samples_interrupt_rate(uint8_t freqKHz);

extern bool volatile stereo_channel_paused;
extern bool volatile mono_channel_paused;

#endif