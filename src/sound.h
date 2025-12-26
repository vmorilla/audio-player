#ifndef _SOUND_H_
#define _SOUND_H_

#include <stdint.h>

typedef enum
{
    STEREO_CHANNEL,
    LEFT_CHANNEL,
    RIGHT_CHANNEL,
    MONO_CHANNEL
} SoundChannelId;

// typedef struct SoundChannelStruct
// {
//     bool paused;                     //                DS.B 1       ; 1 = paused, 0 = playing
//     volatile char *cursor;           //                DS.W 1       ; current cursor in the buffer
//     int8_t file_handle;              //           DS.B 1       ; file handle associated to the channel
//     int8_t queued_file_handle;       //    DS.B 1       ; queued file handle to be played when the current one ends
//     bool loop_mode;                  //             DS.B 1       ; loop mode (0 = no loop, 1 = loop)
//     const char *buffer_area;         //           DS.W 1       ; buffer address (low part)
//     const uint16_t buffer_area_size; //      DS.W 1       ; buffer size in bytes
//     void (*callback)(void);          //              DS.W 1       ; callback function when the sound ends
// } SoundChannel;

int8_t play_sound_file(SoundChannelId channel, const char *filename, bool loop);
int8_t play_sound_file_callback(SoundChannelId channel, const char *filename, void (*callback)(void));

int8_t queue_sound_file(SoundChannelId channel, const char *filename, bool loop);
int8_t queue_sound_file_callback(SoundChannelId channel, const char *filename, void (*callback)(void));

void sound_interrupt_handler(void);

/**
 * Sets the interrupt rate for sound samples generation in kHz
 */
void set_sound_samples_interrupt_rate(uint8_t freqKHz);

extern bool volatile stereo_channel_paused;
extern bool volatile mono_channel_paused;

extern void (*volatile stereo_channel_callback)(void);
extern void (*volatile mono_channel_callback)(void);

#endif