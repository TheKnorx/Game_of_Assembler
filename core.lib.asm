; This library contains functions and variables used by this project.
; Most functions are own implementations/replacments for glibc functions.
; The ultimate goal of this library is to replace the glibc usage across this project entirely

; Syscall register assignment: 
; rdi - rsi - rdx - r10 - r8 - r9 - rax = Syscall-number

; Functions in this file with have the following preceeding commentary layout:
; Replacement-function for:
; <glibc function signature>
; (Optional) --> needed libcalls: <names of need functions from this library> 
; (Optional) --> needed syscalls: <names of needed linux kernel syscalls>
; (Optional) --> needed asm-inst: <needed assembly instructions>
; (Optional) >>> <kernel syscall signatures> or <glibc function signatures>
; (Optional) <<< <additional implementation notes - behavior, special cases, ...>

; NOTE: all types (+ their extensions) in all signatures of the glibc functions
; are all seen as 64-bit/8-bytes in size here --> they take up one r* register each
; This is for protability purposes


section .bss
section .data
section .text

%include "core.lib.inc"

; macro for doing the prolog
%macro ENTER 0
    push    rbp
    mov     rbp, rsp
    sub     rsp, -16        ; align the stack to multiple of 16
%endmacro

; macro for doing the epilog
; not using 'leave` here cause of performance
%macro LEAVE 0
    mov     rsp, rbp
    pop     rbp
%endmacro


; Replacement-function for: 
; int printf(const char *restrict format, ...);
; --> needed libcalls: 
; --> needed syscalls: 
; --> needed asm-inst: 
sys_printf: 
    .enter: ENTER
    



    .leave: LEAVE
    ret


; Replacement-function for: 
; void *malloc(size_t size);
; --> needed syscalls: mmap
; >>> void *mmap(void addr[.length], size_t length, int prot, int flags,
;                int fd, off_t offset);
; <<< if size == 0: return invalid pointer NULL
; <<< if size < 0: size = size_t % size (cause size_t is unsigned)
sys_malloc: 
    .enter: ENTER

    cmp     rdi, 0x00   ; check if parameter size_t size is 0
    je      .invalid    ; if its 0, then return NULL
    ; else allocate the memory

    mov     rax, SYS_MMAP ; move syscall number into rax
    mov     rsi, rdi    ; parameter length = size_t size in rdi
    add     rsi, 0x08   ; add additional 64-bit (8-byte) for headers and stuff to size
    push    rsi         ; push (new) size of memory to stack for later use - stack alignment doesnt matter now
    xor     rdi, rdi    ; parameter addr[.length] = NULL
    mov     rdx, PROT_READ | PROT_WRITE ; parameter prot
    mov     r10, MAP_PRIVATE | MAP_ANONYMOUS ; parameter flags
    mov     r8, -1      ; parameter fd = -1
    xor     r9, r9      ; parameter offset = 0
    syscall             ; Execute mmap --> rax = addr of allocated memory or MAP_FAILED

    cmp     rax, MAP_FAILED ; compare if rax is invalid / mmap failed 
    je      .invalid        ; if its invalid, set rax to NULL and return from this function 
    ; else write allocation information into the memory block
    pop     rsi             ; get pushed value of memory size from stack
    mov     [rax], rsi      ; move into the memory region the size of it that we pushed onto stack before
    lea     rax, [rax+8]    ; add 64-bit/8-byte to the pointer -> rax now points to usable memory
    jmp     .leave          ; return from function - pushed rsp is removed with epilog

    .invalid: 
        mov     rax, NULL  ; move NULL into rax
    .leave: LEAVE
    .return: ret


; Replacement-function for: 
; void *calloc(size_t nmemb, size_t size);
; --> needed libcalls: sys_malloc, sys_memset
; >>> void *malloc(size_t size);
; >>> void *memset(void s[.n], int c, size_t n);
; <<< if nmemb * size > sizeof(int): we dont care and pass it to malloc where size = size_t % size
sys_calloc: 
    .enter: ENTER

    mov     rax, rdi    ; move factor into rax for MUL
    xor     rdx, rdx    ; clear rdx so it doesnt mess with MUL
    mul     rsi         ; rsi*rax = size_t nmemb * size_t size
    push    rax         ; push rax to stack for later use
    mov     rdi, rax    ; parameter size = calculated memory size
    call    sys_malloc  ; allocate memory with sys_malloc --> ptr in rax

    cmp     rax, NULL   ; compare if rax contains a valid pointer
    je      .leave      ; if it does not, immediately return from function
    ; else zero out the memory
    mov     rdi, rax    ; parameter s[.n] = move pointer to memory into rdi
    mov     rsi, 0x00   ; parameter c = 0x00 (empty byte)
    mov     rdx, [rsp]  ; parameter n = pushed size of memory from stack
    call    sys_memset  ; set memory at adress in rdi to 0x00
    ; fall through to leave section -> pushed memory size will be removed in epilog

    .leave: LEAVE
    .return: ret


; Replacement-function for: 
; void *realloc(void *_Nullable ptr, size_t size);
; --> needed syscalls: mremap
; >>> void *mremap(void old_address[.old_size], size_t old_size,
;              size_t new_size, int flags, ... /* void *new_address */);
; <<< as this is implemented with 'mremap`, its behavior follows the mremap convention, not the realloc convention!
; <<< on failiure, we return the old address of the old memory but no guarantee that the address is usable
sys_realloc: 
    .enter: ENTER
    push    rdi             ; save old address to memory to stack for potential later use

    mov     rax, SYS_MREMAP ; move syscall number into rax
    lea     rdi, [rdi-8]    ; parameter old_address[.old_size] - subtract 64-bits (8-bytes) from pointer
    mov     rdx, rsi        ; parameter: new_size - add passed new size from rsi into rdx
    mov     rsi, [rdi]      ; parameter old_size - move size of memory into rsi
    mov     r10, MREMAP_MAYMOVE  ; parameter int flags
    syscall                 ; execute mremap --> rax = new address
    cmp     rax, MAP_FAILED ; check if rax is invalid / mremap failed 
    jne     .leave          ; if its a valid pointer, then leave and return from this function
    ; else we set the pointer to NULL
    .invalid:
        pop     rax         ; get pushed old address from stack and save into rax
    ; pushed value will be automatically removed by epilog
    .leave: LEAVE
    .return: ret


; Replacement-function for: 
; void free(void *_Nullable ptr);
; --> needed syscalls: munmap
; >>> int munmap(void addr[.length], size_t length)
; <<< if munmap returned with an error, we also return the error here, but dont really care about it --> just in case
sys_free:
    .enter: ENTER 

    cmp     rdi, NULL       ; compare if parameter ptr is 0
    je      .leave          ; if its NULL, we do nothing
    ; else we free the memory

    mov     rax, SYS_MUNMAP ; move syscall number into rax
    lea     rdi, [rdi-8]    ; parameter ptr - subtract the header-area from memory pointer
    mov     rsi, [rdi]      ; parameter length - is stored in the first 8 byte of the memory
    syscall                 ; free the memory pointed to by parameter ptr --> rax = success/error
    ; anyways - return with rax, although we dont really need to 

    .leave: LEAVE
    .return: ret
    
    

; Replacement-function for: 
; size_t strlen(const char *s);
; --> needed syscalls: -
sys_strlen: 
    .enter: ENTER

    xor     rax, rax        ; clear rax and use it for length storage
    xor     rcx, rcx        ; clear index
    .for: 
        cmp     byte [rdi+rcx], 0x00 ; compare current char to null-terminator
        je      .leave     ; if it matches, return from function
        inc     rax         ; increment length
        jmp     .for        ; continue the loop

    .leave: LEAVE
    .return: ret

; Replacement-function for:
; void *memset(void s[.n], int c, size_t n);
; --> needed asm-inst: rep stosb
sys_memset:
    ; no prolog or epilog needed 

    ; rdi - parameter s[.n] - rdi already contains destination memory address
    mov     rcx, rdx    ; move parameter n into counter register
    mov     al, sil     ; move parameter c into al
    cld                 ; clear direction flag so that we overwrite upwards from the base memory address
    rep stosb           ; overwrite whole allocated memory with char in al

    .return: ret