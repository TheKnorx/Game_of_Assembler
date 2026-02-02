#all: main.asm io_handler.asm memory_handler.asm field_handler.asm
#	../compile_wlib_gcc.sh $^

# Makefile for building the whole project and creating the executable ./main
# uses nasm for compiling and gcc (ld) for linking

NASM ?= nasm
CC   ?= gcc

NASMFLAGS := -f elf64 -g -F dwarf
LDFLAGS   := -no-pie

MAIN := main.asm
SRCS := main.asm io_handler.asm memory_handler.asm field_handler.asm

BUILD_DIR := build
TARGET := $(basename $(MAIN))

# Object list matches the script: build/<basename>.o (basename only)
OBJS := $(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))

.PHONY: all clean

all: $(TARGET)

# Link step (same as: gcc -no-pie <objs> -o ./main)
$(TARGET): $(BUILD_DIR) $(OBJS)
	@printf '\n== Linking -> %s/%s ==\n' "$$(pwd)" "$(TARGET)"
	@$(CC) $(LDFLAGS) $(OBJS) -o "$(TARGET)" 2>&1 | sed 's/^/  /'
	@printf '\nBuild successful: %s/%s\n' "$$(pwd)" "$(TARGET)"

# Ensure build directory exists
$(BUILD_DIR):
	@mkdir -p "$(BUILD_DIR)"

# Compile each .asm into build/<basename>.o (same flags/output formatting)
$(BUILD_DIR)/%.o: %.asm | $(BUILD_DIR)
	@printf '\n== Compiling: %s ==\n' "$$(realpath $< 2>/dev/null || echo $<)"
	@$(NASM) $(NASMFLAGS) "$<" -o "$@" 2>&1 | sed 's/^/  /'
	@printf '  -> %s\n' "$@"

clean:
	@rm -rf "$(BUILD_DIR)" "$(TARGET)"
