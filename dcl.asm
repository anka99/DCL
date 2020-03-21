SYS_WRITE equ 1
SYS_EXIT equ 60
STDOUT equ 1
MAX_LINE equ 42
ARG_LENGTH equ 42
ARGC equ 5
LOW equ 49
UP equ 90

global _start

section .data
global arr
arr times 42 dw 0

section .rodata

new_line db `\n`

section .text

%macro my_exit 0
        mov     rdi, rdx
        mov     eax, SYS_EXIT
        syscall
%endmacro

_start:
        mov     rax, ARGC               ;store number of args in rax
        cmp     rax, [rsp]
        jne     exit_1
        mov     r8, ARG_LENGTH
        lea     rbp, [rsp + 8 * 2]      ;first program argument (left)
        call    _check_perm
        lea     rbp, [rsp + 8 * 3]      ;second program argument (right)
        call    _check_perm
        lea     rbp, [rsp + 8 * 4]
        mov     r8, 2
        call    _check_perm
exit_0:
        mov     eax, SYS_EXIT
        xor     edi, edi
        syscall
exit_1:
        mov     eax, SYS_EXIT
        mov     edi, 1
        syscall
_check_perm:
        push    rax
        push    rbx
        push    rcx
        push    rdx
        mov     rbx, [rbp]       
        mov     rax, 0
        mov     rcx, 0
check_perm_loop:  ;valid program arguments
        mov     cl, [rbx]
        cmp     cl, 0
        je      check_perm_end               ;end of the loop

        cmp     cl, 49
        jl      exit_1                  ;character out of the defined range

        cmp     cl, 90
        jg      exit_1                 ;character out of the defined range

        cmp     r8, 2
        je      check_perm_loop_inc

        mov     rdx, arr
        add     rdx, rcx
        sub     rdx, 49     
        cmp     byte [rdx], 0
        jne     exit_1
        mov     byte [rdx], 1
        add     rdx, 49
        sub     rdx, rcx
check_perm_loop_inc:
        inc     rbx
        inc     rax          
        jmp     check_perm_loop         

check_perm_end:
        cmp     rax, r8
        jne     exit_1
        mov     rdx, 0
check_perm_end_loop:
        mov     byte [arr + rdx], 0
        inc     rdx
        cmp     rdx, 42
        jl      check_perm_end_loop
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax
        jmp     exit_0

