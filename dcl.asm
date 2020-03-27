SYS_WRITE equ 1
SYS_EXIT equ 60
STDOUT equ 1
MAX_LINE equ 42
ARG_LENGTH equ 42
ARGC equ 5
LOW equ 49
UP equ 90
BUFFER_LENGTH equ 4
T equ 35
R equ 33
L equ 27

global _start

section .bss
        buffer resb BUFFER_LENGTH
        arg_R resb 8 ;pointers to pointers to the beginning of the strings
        arg_L resb 8
        arg_T resb 8
        arg_lr resb 8
        text_length resb 8
section .data
        arr times 42 dw 0
        arr_r times 42 dw 0
        arr_l times 42 dw 0
        arr_t times 42 dw 0
        arr_key times 2 dw 0
        arr_r_rev times 42 dw 0
        arr_l_rev times 42 dw 0

section .rodata
        new_line db `\n`

section .text

%macro my_exit 1
        mov     rdi, %1
        mov     eax, SYS_EXIT
        syscall
%endmacro

;arguments: pointer to array start, array length, value subtracted, destination pointer
%macro reval_arr 4
        push    r9
        push    rsi
        mov     rdi, %1 ;pointer to array start
        mov     rsi, %2 ;array length
        mov     rdx, %3 ;value subtracted 
        xor     rcx, rcx ;set iterator to 0
%%reval_arr_loop:
        cmp     rcx, rsi
        je      %%reval_arr_end
        sub     [rdi], rdx
        mov     r9, [rdi]
        mov     [%4 + rcx], r9
        inc     rdi
        inc     rcx
        jmp     %%reval_arr_loop
%%reval_arr_end:
        pop     rsi
        pop     r9
%endmacro

;pointer to letter shifted, shift value
%macro shift_letter 2
        add     [%1], %2
        cmp     [%1], 0
        jge      %%compare_42
        add     [%1], ARG_LENGTH
%%compare_42:
        cmp     [%1], ARG_LENGTH
        je      %%end    
        sub     [%1], ARG_LENGTH 
%%end:
%endmacro

;perm, conainer, length
%macro reverse_perm 3
        xor     rsi, rsi ;set itarator to 0
        xor     rdi, rdi ;set letter to 0
%loop:
        cmp     rsi, %3 
        je      %end 
        mov     rsi, [%1 + rdi] ;mov current perm sign to rsi
        mov     [%2 + rsi], rdi ;mov position of rsi sign on rsi'th place in container
        inc     rsi
        jmp
%end:
%endmacro

;pointer to letter, pointer to the beggining of array
%macro perm_letter 2
        push    rdi
        mov     rdi, [%1]
        mov     [%1], [%2 + rdi]
        pop     rdi
%endmacro
       
_start:
        mov     rax, ARGC               ;store number of args in rax
        lea     rbp, [rsp]
        call    _check_args

start_loop:
        call    _read_input             ;set rax on number of read bytes
        mov     [text_length], rax
        call    _encrypt
        call    _print_result
        cmp     byte [text_length], BUFFER_LENGTH ;TODO: possible error with byte
        je      start_loop              ;continue reading
exit_0:
        mov     eax, SYS_EXIT
        xor     edi, edi
        syscall
exit_1:
        mov     eax, SYS_EXIT
        mov     edi, 1
        syscall

_read_input:
        push    rdi
        push    rsi
        push    rdx
        mov     rax, 0
        mov     rdi, 0
        mov     rsi, buffer
        mov     rdx, BUFFER_LENGTH
        syscall
        pop     rdx
        pop     rsi
        pop     rdi
        ret
_encrypt:
        push    rbx
        push    rcx
        mov     rbx, 0 ;iterator
        mov     rcx, buffer
        reval_arr buffer, [text_length], LOW, buffer ;decrease value of letters to [0;42)
encrypt_loop:
        lea     r8, [rcx + rbx] ;
        lea     rsi, [arr_key] ;l
        lea     rdi, [arr_key + 1] ;r

        shift_letter  r8, [rdi] ;Qr
        perm_letter r8, arr_r  ;R
        shift_letter r8, -1 * rdi    ;Qr^-1
        shift_letter r8, rsi   ;Ql
        perm_letter r8, arr_l;L
        shift_letter r8, -1 * rsi;Ql^-1
        perm_letter r8, arr_t;T
        shift_letter r8, rsi;Ql
        perm_letter  r8, arr_l_rev;L^-1
        shift_letter r8, -1 * rsi ;Ql^-1
        shift_letter r8, rdi;Qr
        perm_letter r8, arr_r_rev;R^-1
        shift_letter r8, -1 * rdi;Qr^-1
        
        shift_letter rdi, 1
encrypt_loop_posR:
        cmp     [rdi], R
        jne     encrypt_loop_posL
        shift_letter rsi, 1
encrypt_loop_posL:
        cmp     [rdi], L
        jne     encrypt_loop_posL
        shift_letter rsi, 1
encrypt_loop_posT:
        cmp     [rdi], T
        jne     encrypt_loop_posL
        shift_letter rsi, 1

        inc     rbx
encrypt_loop_end:
        reval_arr buffer, [text_length], -49, buffer ;increase value of letters to the original one
        pop     rcx
        pop     rbx
        ret

;pointer to letter, pointer to array with permutiation

_print_result:
        push    rax
        push    rdi
        push    rsi
        mov     rax, SYS_WRITE
        mov     rdi, STDOUT
        mov     rsi, arr_l
        mov     rdx, 42
        syscall
        pop     rsi
        pop     rdi
        pop     rax
        ret
_check_args:
        cmp     rax, [rbp]
        jne     exit_1
        mov     r9, 0
        mov     r8, ARG_LENGTH
        add     rbp, 8 * 2      ;first program argument (L)
        mov     rsi, arr_l
        call    _check_perm
        add     rbp, 8          ;second program argument (R)
        mov     rsi, arr_r
        call    _check_perm

        add     rbp, 8          ;third program argument (T)
        mov     rsi, arr_t
        mov     r9, 1
        call    _check_perm

        add     rbp, 8          ;fourth program argument (key)
        mov     r8, 2   
        mov     r9, 0
        mov     rsi, arr_key
        call    _check_perm
        ret
_check_perm:
        push    rax
        push    rbx
        push    rcx
        push    rdx
        push    r10
        mov     rbx, [rbp]     ;pointer to current letter  
        mov     r10, [rbp]      ;pointer to first letter
        mov     rax, 0  ;position being checked
        mov     rcx, 0  ;value of current letter
;.align 16
check_perm_loop:  ;valid program arguments
        mov     cl, [rbx]
        cmp     cl, 0
        je      check_perm_end               ;end of the loop

        cmp     cl, 49
        jl      exit_1                  ;character out of the defined range

        cmp     cl, 90
        jg      exit_1                 ;character out of the defined range

check_perm_loop_T:
        cmp     r9, 0
        je      check_perm_loop_LRT ; skip this part for R, L and key

        sub     rcx, 49
        cmp     rcx, rax
        je      exit_1 ;1-element cycle is incorrect

        add     r10, rcx                                                        ;jump to the cl'th letter
        sub     byte [r10], 49                                                  ;adjust value of cl'th letter
        cmp     al, [r10]                                                      ;compare position of cl with value of cl'th letter                                                     
        jne     exit_1 ;more than 2-element cycle is incorrect
        add     byte [r10], 49                                                  ;reset value of cl'th letter
        sub     r10, rcx ;reset pointer

        add     cl, 49
check_perm_loop_LRT:
        cmp     r8, 2
        je      check_perm_loop_inc ;skip this part for key

        mov     rdx, arr
        add     rdx, rcx
        sub     rdx, 49     
        cmp     byte [rdx], 0
        jne     exit_1
        mov     byte [rdx], 1
        add     rdx, 49
        sub     rdx, rcx
check_perm_loop_inc:
        
        mov     [rsi + rax], cl
        sub     byte [rsi + rax], 49
        inc     rbx
        inc     al          
        jmp     check_perm_loop         

check_perm_end:
        cmp     rax, r8
        jne     exit_1
        mov     rdx, 0
check_perm_end_loop:
        mov     byte [arr + rdx], 0
        inc     rdx
        cmp     rdx, 42
        jl      check_perm_end_loop ;the end of loop filling arr with 0
        pop     r10
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax
        ret

_my_exit:
        mov     rdi, [arr_l + 1]
        mov     eax, SYS_EXIT
        syscall