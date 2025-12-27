# Tools
ASE2NX = ../../../ase2nx/dist/ase2nx.js

# Source and Output files
SOURCE_FILES := $(wildcard *.ase)
OUTPUT_DIR := ../../build/tiles/
OUTPUT_FILES := $(patsubst %.ase,$(OUTPUT_DIR)%.td, $(SOURCE_FILES))

all: $(OUTPUT_FILES)

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(OUTPUT_DIR)%.td: %.ase | $(OUTPUT_DIR)
	$(ASE2NX) tiledefs -o $@ $<

# Clean rule
clean:
	rm -f $(OUTPUT_FILES)

.PHONY: all clean

