# Toolchain
CC := zcc
AS := zcc
LD := zcc

# Build settings
TARGET      := +zxn -subtype=nex
VERBOSITY   := -vn
CRT         := 31
CLIB        := sdcc_iy
COMPILER    := sdcc

# Compiler, assembler and linkerflags
DEBUG_FLAGS := -DDEBUG
C_OPT_FLAGS := -SO3 --max-allocs-per-node200000 --opt-code-size

CFLAGS  := $(TARGET) $(VERBOSITY) --list -c --c-code-in-asm -compiler=$(COMPILER) \
           -clib=$(CLIB) -Cz"--clean" --math32 $(DEBUG_FLAGS) $(C_OPT_FLAGS)
		   
ASFLAGS := $(TARGET) $(VERBOSITY) -c --list -m $(DEBUG_FLAGS) $(C_OPT_FLAGS) 

LDFLAGS= $(TARGET) $(VERBOSITY) --list -m -clib=$(CLIB) -startup=$(CRT) -pragma-include:zpragma.inc
LIBS = -lmath32

# Source files and derived objects
SRCS_C   := $(wildcard *.c) $(wildcard **/*.c)
SRCS_ASM := $(wildcard *.asm) $(wildcard **/*.asm)

OBJS := $(SRCS_C:.c=.o) $(SRCS_ASM:.asm=.o)
DEPS := $(SRCS_C:.c=.d)

# Output dir and files
OUTPUT_DIR = ../build
OUTPUT = $(OUTPUT_DIR)/audio-player.nex

# General rules
all: deps $(OUTPUT) check_length

$(OUTPUT): $(OBJS)
	$(LD) $(LDFLAGS) $(LIBS) -o $(basename $@).bin $^ -create-app

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

%.d: %.c
	$(CC) $(CFLAGS) -M $< > $@

-include $(DEPS)

deps: $(DEPS)

dirs:
	mkdir -p $(OUTPUT_DIR)

clean::
	rm -fR $(OUTPUT) *.o *.bin *.lis *.sym *.d

# Rule to check file length of the main code and show sizes of code bank files after build
# In certain occasions, z88dk was not enforcing the size limits properly (to be double checked)
check_length:
	@FILE=$(basename $(OUTPUT))_CODE.bin; \
	MAX_SIZE=16384; \
	ACTUAL_SIZE=$$(stat -f%z "$$FILE"); \
	if [ $$ACTUAL_SIZE -gt $$MAX_SIZE ]; then \
		echo "Error: $$FILE exceeds the maximum allowed size of $$MAX_SIZE bytes (actual: $$ACTUAL_SIZE bytes)."; \
		exit 1; \
	else \
		echo "$$FILE is within the size limit (actual: $$ACTUAL_SIZE bytes)."; \
		ls -l "$(OUTPUT_DIR)/"*_CODE.bin; \
	fi


# Target-specific bank CFLAGS for all first-level subdirectories
$(foreach dir,$(patsubst %/,%,$(wildcard */)),$(eval $(dir)/%.o: CFLAGS += --codeseg $(dir)_code --constseg $(dir)_const))
# The rule above produces one entry per subdirectory like this:
# game/%.o: CFLAGS += --codeseg game_code --constseg game_const
# Such bank definitions must be defined in mmap.inc

# Phony targets
.PHONY:: all clean deps




