# Audio player test for ZX Next

Audio samples in the repository are property of [Alien Mind](https://github.com/alienmind)



## Driver
  DEFVARS 0               
  {
    SOUND_CHANNEL_PAUSED                DS.B 1       ; 1 = paused, 0 = playing
    SOUND_CHANNEL_CURSOR                DS.W 1       ; current cursor in the buffer
    SOUND_CHANNEL_BUFFER_AREA           DS.W 1       ; buffer address (low part)
    SOUND_CHANNEL_BUFFER_AREA_SIZE      DS.W 1       ; buffer size in bytes
    SOUND_CHANNEL_FILE_HANDLE           DS.B 1       ; file handle associated to the channel
    SOUND_CHANNEL_QUEUED_FILE_HANDLE    DS.B 1       ; queued file handle to be played when the current one ends
    SOUND_CHANNEL_LOOP_MODE             DS.B 1       ; loop mode (0 = no loop, 1 = loop)
    SOUND_CHANNEL_CALLBACK              DS.W 1       ; callback function when the sound ends 
    SOUND_CHANNEL_STRUCT_SIZE    
  } 

## Main thread