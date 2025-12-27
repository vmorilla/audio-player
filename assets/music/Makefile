# Tools
FFMPEG = ffmpeg -v error
MONO_STEREO = ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1

# Replaces 0xFF bytes with 0xFE. 0xFF will be used to mark the end of a sequence in
# the sound player, so it cannot appear in the raw data.
RAW_PREPROCESS = perl -pe 's/\xff/\xfe/g'


# Source and Output files
SOURCE_FILES := $(wildcard *.wav *.mp3)
OUTPUT_DIR := ../../build/music/
OUTPUT_FILES := $(patsubst %.wav,$(OUTPUT_DIR)%.raw,$(filter %.wav,$(SOURCE_FILES))) \
                $(patsubst %.mp3,$(OUTPUT_DIR)%.raw,$(filter %.mp3,$(SOURCE_FILES)))

# Coding options
# -ac 2: stereo
# -ar 16000: 16kHz sample rate
# -acodec pcm_u8: 8-bit unsigned PCM
SOUND_OPTIONS = -ar 8000 -acodec pcm_u8 -af loudnorm=I=-16:LRA=11:TP=-1.5 -y -f u8 #-f wav

all: $(OUTPUT_FILES)

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(OUTPUT_DIR)%.raw: %.wav | $(OUTPUT_DIR)
	$(FFMPEG) -i $< $(SOUND_OPTIONS) - | $(RAW_PREPROCESS) > $@

$(OUTPUT_DIR)%.raw: %.mp3 | $(OUTPUT_DIR)
	$(FFMPEG) -i $< $(SOUND_OPTIONS) - | $(RAW_PREPROCESS) > $@

# Clean rule
clean:
	rm -f $(OUTPUT_FILES)

.PHONY: all clean

