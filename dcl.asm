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
%macro right_shift_letter 2
        add     [%1], %2
        cmp     byte [%1], ARG_LENGTH
        jl      %%end    
        sub     byte [%1], ARG_LENGTH 
%%end:
%endmacro

;pointer to letter shifted, shift value
%macro left_shift_letter 2
        cmp     [%1], %2
        jge     %%sub
        add     byte [%1], ARG_LENGTH
%%sub:
        sub     [%1], %2
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

;pointer to letter, pointer to the beggining of array
%macro perm_letter 2
        push    rdi
        xor     rdi, rdi
        mov     dil, [%1]
        mov     dil, [%2 + rdi]
        mov     [%1], dil
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
        mov     [text_length], rax
        call    _encrypt
        call    _print_result
        cmp     qword [text_length], BUFFER_LENGTH ;TODO: possible error with byte
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
        xor     rdi, rdi
        xor     rsi, rsi
        mov     rbx, 0 ;iterator
        reval_arr buffer, [text_length], LOW, buffer ;decrease value of letters to [0;42)
        lea     rdx, [arr_key] ; l pointer
        lea     r9 , [arr_key + 1] ;r pointer
encrypt_loop:
        cmp     rbx, [text_length]
        je      encrypt_loop_end ;end the loop if iterator reaches text length

        mov     r11, 1
        right_shift_letter r9, r11b ;r++ 
encrypt_loop_posR:
        cmp     byte [r9], R
        jne     encrypt_loop_posL
        right_shift_letter rdx, r11b ;l++
encrypt_loop_posL:
        cmp     byte [r9], L
        jne     encrypt_loop_posT
        right_shift_letter rdx, r11b ; l++
encrypt_loop_posT:
        cmp     [r9], byte T
        jne     encrypt_loop_main
        right_shift_letter rdx, r11b ;l++ 
        align   16
encrypt_loop_main:
        mov     rsi, [arr_key] ;l value
        mov     rdi, [arr_key + 1] ;r value
        lea     r8, [buffer + rbx] ;move poiner to the encrypted char to r8

        cmp     byte [r8], 0 ;user input validation
        jl      exit_1

        cmp     byte [r8], ARG_LENGTH
        jge     exit_1

        right_shift_letter  r8, dil ;Qr
        perm_letter r8, arr_r  ;R
        left_shift_letter r8, dil    ;Qr^-1
        right_shift_letter r8, sil   ;Ql
        perm_letter r8, arr_l ;L
        left_shift_letter r8, sil;Ql^-1
        perm_letter r8, arr_t;T
        right_shift_letter r8, sil;Ql
        perm_letter  r8, arr_l_rev;L^-1
        left_shift_letter r8, sil ;Ql^-1
        right_shift_letter r8, dil ;Qr
        perm_letter r8, arr_r_rev;R^-1
        left_shift_letter r8, dil;Qr^-1
        

        inc     rbx
        jmp     encrypt_loop
encrypt_loop_end:
        reval_arr buffer, [text_length], -49, buffer ;increase value of letters to the original one
        ret

_print_result:
        mov     rax, SYS_WRITE
        mov     rdi, STDOUT
        mov     rsi, buffer
        mov     rdx, [text_length]
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