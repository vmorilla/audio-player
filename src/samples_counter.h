#ifndef _SAMPLES_COUNTER_H_
#define _SAMPLES_COUNTER_H_

#include <stdint.h>

void samples_counter_interrupt_handler(void);
extern volatile uint16_t sound_samples_played;

#endif /* _SAMPLES_COUNTER_H_ */