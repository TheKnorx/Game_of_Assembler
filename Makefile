all: main.asm io_handler.asm memory_handler.asm field_handler.asm
	../compile_wlib_gcc.sh $^