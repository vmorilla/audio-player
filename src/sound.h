#ifndef _SOUND_H_
#define _SOUND_H_

#include <stdint.h>

#define SOUND_SAMPLES_BUFFER_SIZE 256

void play_sound_file(const char *filename) __z88dk_fastcall;

// bit 0: buffer 0 empty, bit 1: buffer 1 empty
extern volatile uint8_t empty_buffers_mask;

extern uint8_t SOUND_SAMPLES_BUFFER[2][SOUND_SAMPLES_BUFFER_SIZE];

/**
 * Sets the interrupt rate for sound samples generation in kHz
 */
void set_sound_samples_interrupt_rate(uint8_t freqKHz);

#endif