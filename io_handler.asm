section .bss
section .data
section .text

global try_ascii_to_int

; function for converting a ascii encoded number to a integer
; yes we could use atoi or snprintf or something similar to this, but where would be the fun in that? why dont DIY?
; (char* ascii_number)[int number]
try_ascii_to_int:  
    ; Prolog
    push    rbp
    mov     rbp, rsp
    and     rsp, -16

    mov     rsi, rdi       ; copy ascii string into source register
    xor     rdi, rdi       ; clear rdi & use it for temporary storage of current extracted ascii char
    xor     rax, rax       ; clear rax for storing/returning the extracted number
    xor     rcx, rcx       ; clear counter registerfor indexing the string
    mov     r8, 0xA        ; factor for MUL to make space for next number
    .for:  ; loop through every ascii char
        mov    dil, [rsi+rcx]  ; move current byte to be converted into 8-bit part of rdx
        cmp    dil, 0x00       ; if the current byte is a null terminator
        je     .return         ; we are finished and return from this function
        ; else continue converting the ascii

        mul    r8              ; multiply rax by 10 so to make space for another number
        sub    dil, 0x30       ; sub 32 from ascii to convert it to int
        add    rax, rdi        ; add the int to rax
        inc    rcx             ; counter++
        jmp    .for            ; continue the loop

    .return:  ; return from function --> number in rax
        ; Epilog
        mov    rsp, rbp
        pop    rbp
        ret


