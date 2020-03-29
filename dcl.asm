SYS_WRITE equ 1
SYS_EXIT equ 60
STDOUT equ 1
ARG_LENGTH equ 42
ARGC equ 5
LOW equ 49
UP equ 90
BUFFER_LENGTH equ 4096
T equ 35
R equ 33
L equ 27

global _start

section .bss
        buffer resb BUFFER_LENGTH
        text_length resb 8
section .data
        arr times 42 db 0
        arr_r times 42 db 0
        arr_l times 42 db 0
        arr_t times 42 db 0
        arr_key times 2 db 0
        arr_r_rev times 42 db 0
        arr_l_rev times 42 db 0

section .text

%macro my_exit 1
        mov     rdi, %1
        mov     eax, SYS_EXIT
        syscall
%endmacro

;arguments: pointer to array start, array length, value subtracted, destination pointer
%macro reval_arr 4
        mov     rdi, %1 ;pointer to array start
        mov     r14, %2 ;array length
        mov     rdx, %3 ;value subtracted 
        xor     rcx, rcx ;set iterator to 0
%%reval_arr_loop:
        cmp     rcx, r14
        je      %%reval_arr_end
        sub     [rdi], rdx
        mov     r13, [rdi]
        mov     [%4 + rcx], r13
        inc     rdi
        inc     rcx
        jmp     %%reval_arr_loop
%%reval_arr_end:
%endmacro

;8-bit value of letter, shift value, 32-bit value of letter
%macro right_shift_letter 3
        add     %1, %2
        mov     r15d, %3
        sub     r15d, ARG_LENGTH
        cmp     %1, ARG_LENGTH
        cmovge  %3, r15d
%endmacro

;8-bit value of letter, shift value, 32-bit value of letter
%macro left_shift_letter 3
        add     %1, ARG_LENGTH
        sub     %1, %2
        mov     r15d, %3
        sub     r15b, ARG_LENGTH
        cmp     %1, ARG_LENGTH
        cmovge  %3, r15d
%endmacro

;perm, conainer, length
%macro reverse_perm 3
        push    rdi
        push    rsi
        push    rcx
        xor     rsi, rsi ;set itarator to 0
        xor     rdi, rdi ;set letter to 0
%%loop:
        cmp     rsi, %3 
        je      %%end 
        mov     dil, [%1 + rsi] ;mov current perm sign to rdi
        lea     rcx, [%2 + rdi]
        mov     [rcx], sil ;mov position of rdi sign on rdi'th place in container
        inc     rsi
        jmp     %%loop
%%end:
        pop     rcx
        pop     rsi
        pop     rdi
%endmacro
       
_start:
        mov     rax, ARGC               ;store number of args in rax
        lea     rbp, [rsp]
        call    _check_args
        reverse_perm arr_l, arr_l_rev, ARG_LENGTH
        reverse_perm arr_r, arr_r_rev, ARG_LENGTH
start_loop:
        call    _read_input             ;set rax on number of read bytes
        mov     r12, rax
        call    _encrypt
        call    _print_result
        cmp     qword r12, BUFFER_LENGTH ;TODO: possible error with byte
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
        mov     rax, 0
        mov     rdi, 0
        mov     rsi, buffer
        mov     rdx, BUFFER_LENGTH
        syscall
        ret
_encrypt:
        xor     r8, r8
        xor     rdi, rdi
        xor     rsi, rsi
        xor     r11, r11
        xor     r13, r13
        mov     rbx, 0 ;iterator
        reval_arr buffer, r12, LOW, buffer ;decrease value of letters to [0;42)
        lea     rdx, [arr_key] ;l pointer
        lea     r9, [arr_key + 1] ;r pointer

        mov     sil, [arr_key] ;l value
        mov     dil, [arr_key + 1] ;r value
encrypt_loop:
        cmp     rbx, r12
        je      encrypt_loop_end ;end the loop if iterator reaches text length

        mov     r13, sil
        mov     r11, 1
        right_shift_letter sil, r11b, esi
        right_shift_letter dil, r11b, edi ;r++ 
encrypt_loop_posR:
        cmp     byte dil, R
        jne     encrypt_loop_posL
        right_shift_letter sil, r11b, esi ;l++
encrypt_loop_posL:
        cmp     byte dil, L
        jne     encrypt_loop_posT
        right_shift_letter sil, r11b, esi ; l++
encrypt_loop_posT:
        cmp     byte dil, T
        jne     encrypt_loop_main
        right_shift_letter sil, r11b, esi ;l++ 
        ;align   16
encrypt_loop_main:
        mov     [rdx], sil ;actualize l
        mov     [r9], dil ; actualize r

        mov     r8b,  [buffer + rbx] ;move poiner to the encrypted char to r8b

        cmp     byte r8b, 0 ;user input validation
        jl      exit_1

        cmp     byte r8b, ARG_LENGTH
        jge     exit_1

        right_shift_letter  r8b, dil, r8d ;Qr
        mov     r8b, [arr_r + r8] ;R
        left_shift_letter r8b, dil, r8d      ;Qr^-1
        right_shift_letter r8b, sil, r8d    ;Ql
        mov     r8b, [arr_l + r8] ;L
        left_shift_letter r8b, sil, r8d      ;Ql^-1
        mov     r8b, [arr_t + r8] ;T
        right_shift_letter r8b, sil, r8d     ;Ql
        mov     r8b, [arr_l_rev + r8] ;L^-1
        left_shift_letter r8b, sil, r8d      ;Ql^-1
        right_shift_letter r8b, dil, r8d     ;Qr
        mov     r8b, [arr_r_rev + r8] ;R^-1
        left_shift_letter r8b, dil, r8d      ;Qr^-1

        mov     [buffer + rbx], r8b
        inc     rbx
        jmp     encrypt_loop
encrypt_loop_end:
        mov     [arr_key], sil ;l value
        mov     [arr_key + 1], dil ;r value
        reval_arr buffer, r12, -49, buffer ;increase value of letters to the original one
        ret

_print_result:
        mov     rax, SYS_WRITE
        mov     rdi, STDOUT
        mov     rsi, buffer
        mov     rdx, r12
        syscall
        ret
_check_args:
        cmp     rax, [rbp]      ;if number of arguments is invalid - exit 1
        jne     exit_1
        mov     r9, 0           ;set flag for T permutation false
        mov     r8, ARG_LENGTH  ;store length of argument checked in r8
        add     rbp, 8 * 2      ;first program argument (L)
        mov     rsi, arr_l      ;store pointer to permutation container in rsi
        call    _check_perm
        add     rbp, 8          ;second program argument (R)
        mov     rsi, arr_r      ;store 
        call    _check_perm

        add     rbp, 8          ;third program argument (T)
        mov     rsi, arr_t
        mov     r9, 1           ;set flag for T permutation true
        call    _check_perm

        add     rbp, 8          ;fourth program argument (key)
        mov     r8, 2           ;set r8 to the length of key
        mov     r9, 0           ;set flag for T permutation false again
        mov     rsi, arr_key
        call    _check_perm
        ret
_check_perm:
        mov     rbx, [rbp]      ;pointer to current letter  
        mov     r10, [rbp]      ;pointer to first letter
        xor     rcx, rcx        ;position being checked
        xor     rax, rax        ;value of current letter
;.align 16
check_perm_loop:  ;valid program arguments
        mov     cl, [rbx]
        cmp     cl, 0
        je      check_perm_end  ;end of the loop 

        cmp     cl, 49
        jl      exit_1          ;character out of the defined range - exit 1

        cmp     cl, 90
        jg      exit_1          ;character out of the defined range - exit 1

check_perm_loop_T:
        cmp     r9, 0
        je      check_perm_loop_LRT ;skip this part for R, L and key

        sub     rcx, 49          ;reduce letter's value to the range of [0, 42)
        cmp     rcx, rax
        je      exit_1           ;1-element cycle is incorrect - exit 1
                                                       
        sub     byte [r10 + rcx], 49 ;adjust value of rcx'th letter                                                 
        cmp     al, [r10 + rcx]      ;compare position of cl with value of cl'th letter                                                     
        jne     exit_1               ;more than 2-elements cycle is incorrect
        add     byte [r10 + rcx], 49 ;reset value of cl'th letter

        add     cl, 49
check_perm_loop_LRT:
        cmp     r8, 2
        je      check_perm_loop_inc ;skip this part for key

        mov     rdx, arr
        add     rdx, rcx        ;jump to letter's place in occurences array
        sub     rdx, 49     
        cmp     byte [rdx], 0   ;if the letter have already appeared - exit 1
        jne     exit_1
        mov     byte [rdx], 1   ;notice, that letter appeared
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
        jne     exit_1 ;exit_1 ;???
        mov     rdx, 0
check_perm_end_loop:
        mov     byte [arr + rdx], 0
        inc     rdx
        cmp     rdx, 42
        jl      check_perm_end_loop ;the end of loop filling arr with 0
        ret

_my_exit:
        mov     rdi, r8
        mov     eax, SYS_EXIT
        syscall