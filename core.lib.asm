; This library contains functions and variables used by this project.
; Most functions are own implementations/replacments for glibc functions.
; The ultimate goal of this library is to replace the glibc usage across this project entirely

section .bss
section .data
section .text

; macro for doing the prolog
%macro ENTER
    .enter:
    push    rbp
    mov     rbp, rsp
    sub     rsp, -16        ; align the stack to multiple of 16
%endmacro

; macro for doing the epilog
; I choose not to use 'leave` here, cause of performance  
%macro LEAVE
    .leave:
    mov     rsp, rbp
    pop     rbp
%endmacro

; Replacement-function for: 
; int printf(const char *restrict format, ...);
; --> needed syscalls: 
sys_printf: 
    PROLOG
    


    EPILOG
    ret


; Replacement-function for: 
; void *malloc(size_t size);
; --> needed syscalls: mmap, munmap, mremap
sys_malloc: 
    ret


; Replacement-function for: 
; void *calloc(size_t nmemb, size_t size);
; --> needed syscalls: 
sys_calloc: 
    ret


; Replacement-function for: 
; void free(void *_Nullable ptr);
; --> needed syscalls: 
sys_free: 
    ret
    

; Replacement-function for: 
; size_t strlen(const char *s);
; --> needed syscalls: 
sys_strlen: 
    ENTER

    xor     rax, rax        ; clear rax and use it for length storage
    xor     rcx, rcx        ; clear index
    .for: 
        cmp     [rdi+rcx], 0x00 ; compare current char to null-terminator
        je      .return     ; if it matches, return from function
        inc     rax         ; increment length
        jmp     .for        ; continue the loop

    LEAVE
    ret