# Tools
FFMPEG = ffmpeg -v error

# Source and Output files
SOURCE_FILES := $(wildcard *.mp3)
OUTPUT_DIR := ../../dist/music/
OUTPUT_FILES := $(patsubst %.mp3,$(OUTPUT_DIR)%.raw,$(SOURCE_FILES))

# Coding options
# -ac 2: stereo
# -ar 16000: 16kHz sample rate
# -acodec pcm_u8: 8-bit unsigned PCM
SOUND_OPTIONS = -ac 2 -ar 16000 -acodec pcm_u8 -af loudnorm=I=-16:LRA=11:TP=-1.5 -y -f u8 #-f wav

all: $(OUTPUT_FILES)

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(OUTPUT_DIR)%.raw: %.mp3 | $(OUTPUT_DIR)
	$(FFMPEG) -i $< $(SOUND_OPTIONS) $@

# Clean rule
clean:
	rm -f $(OUTPUT_FILES)

.PHONY: all clean 

