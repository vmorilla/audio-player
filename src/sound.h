#ifndef _SOUND_H_
#define _SOUND_H_

#include <stdint.h>

int8_t play_sound_file(const char *filename);
int8_t load_sound_file(const char *filename) __z88dk_fastcall;

void start_sound(void);
void stop_sound(void);

void sound_interrupt_handler(void);

/**
 * Sets the interrupt rate for sound samples generation in kHz
 */
void set_sound_samples_interrupt_rate(uint8_t freqKHz);

#endif