SYS_WRITE equ 1
SYS_EXIT EQU 60
STDOUT EQU 1
MAX_LINE equ 42

global _start

section .rodata

new_line db `\n`

section .text

_start:
    lea rbp, [rsp + 8]
loop:
    mov rsi, [rbp]
    test rsi, rsi
    jz exit
    cld 
    xor al, al
    mov ecx, MAX_LINE
    mov rdi, rsi
    repne \
    scasb
    mov rdx, rdi
    mov eax, SYS_WRITE
    mov edi, STDOUT
    sub rdx, rsi
    syscall
    mov eax, SYS_WRITE
    mov edi, STDOUT
    sub rdx, rsi
    syscall
    mov eax, SYS_WRITE
    mov edi, STDOUT
    mov rsi, new_line
    mov edx, 1
    syscall
    add rbp, 8
    jmp loop
exit:
    mov eax, SYS_EXIT
    xor edi, edi
    syscall
