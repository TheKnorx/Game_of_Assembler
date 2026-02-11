; File for storing constants that are shared by multiple files

; generell constants
%define NULL 			0x00       ; ((void *) 0)

; syscall number constants: 
%define SYS_MMAP		9
%define SYS_MUNMAP  	11
%define SYS_MREMAP 		25


; map constants: 
%define PROT_READ       0x01
%define PROT_WRITE      0x02
%define PROT_EXEC       0x04
%define PROT_NONE       0x00

%define MAP_SHARED      0x01
%define MAP_PRIVATE     0x02
%define MAP_FIXED       0x10
%define MAP_ANONYMOUS 	0x20

%define MREMAP_MAYMOVE 	0x01

%define MAP_FAILED		-1 ; ((void *) -1)
; %define MAP_FAILED		(~1)+1 ; ((void *) -1)