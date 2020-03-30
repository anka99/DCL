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
        arr_r resb 42
        arr_l resb 42
        arr_t resb 42
        arr_key resb 2
        arr_r_rev resb 42
        arr_l_rev resb 42
section .data
        arr times 42 db 0

section .text

;Applies positive cycle shift to given letter
;Arguments: 8-bit value of letter, shift value, 32-bit value of letter
%macro right_shift_letter 3
        add     %1, %2
        mov     r15d, %3
        sub     r15d, ARG_LENGTH        ;alternative value after shift
        cmp     %1, ARG_LENGTH          ;if value exceeds 42, choose lower one
        cmovge  %3, r15d
%endmacro

;Applies negative cycle shift to given letter 
;Arguments: 8-bit value of letter, shift value, 32-bit value of letter
%macro left_shift_letter 3
        add     %1, ARG_LENGTH
        sub     %1, %2
        mov     r15d, %3
        sub     r15b, ARG_LENGTH        ;alternative value after shift
        cmp     %1, ARG_LENGTH          ;if value exceeds 42, choose lower one
        cmovge  %3, r15d
%endmacro

;Fills given cointainer with inversed permutation
;Arguments: pointer to permutation array, conainer, length of permutation
%macro reverse_perm 3
        xor     rsi, rsi        ;set itarator to 0
        xor     rdi, rdi        ;set letter to 0
%%loop:
        cmp     rsi, %3 
        je      %%end 
        mov     dil, [%1 + rsi] ;move current perm sign to rdi
        lea     rcx, [%2 + rdi]
        mov     [rcx], sil ;move position of rdi sign on rdi'th place in container
        inc     rsi
        jmp     %%loop
%%end:
%endmacro

;Reads user input
%macro read_input 0
        xor     rax, rax
        xor     rdi, rdi
        mov     rsi, buffer             ;
        mov     rdx, BUFFER_LENGTH
        syscall
%endmacro

;Prints encrypted text on standard output
%macro print_result 0
        mov     rax, SYS_WRITE
        mov     rdi, STDOUT
        mov     rsi, buffer     ;pointer to encrypted text
        mov     rdx, r12        ;encrypted text length
        syscall
%endmacro

%macro encrypt 0
        xor     ebx, ebx        ;set iterator to 0
        xor     esi, esi        ;reset temporary register
encrypt_loop:
        cmp     rbx, r12
        je      encrypt_loop_end ;end the loop if iterator reaches text length

        mov     sil, r13b                   ;copy value of l 
        mov     r11, 1                      ;winders shift value
        right_shift_letter sil, r11b, esi   ;alternative value of l
        right_shift_letter r14b, r11b, r14d ;r++ 
encrypt_loop_posR:
        cmp     r14b, R                     ;if r reaches spin position
        cmove   r13d, esi                   ;l++
encrypt_loop_posL:
        cmp     r14b, L                     ;if r reaches spin position
        cmove   r13d, esi                   ;l++
encrypt_loop_posT:
        cmp     r14b, T                     ;if r reaches spin position
        cmove   r13d, esi                   ;l++

encrypt_loop_main:
        mov     r8b,  [buffer + rbx] ;move poiner to the encrypted char to r8b
        sub     r8b, LOW             ;decrease value of letter to range [0:42)
        cmp     byte r8b, 0          ;user input validation
        jl      exit_1

        cmp     byte r8b, ARG_LENGTH
        jge     exit_1

encrypt_sequence:
        right_shift_letter  r8b, r14b, r8d      ;Qr
        mov     r8b, [arr_r + r8]               ;R
        left_shift_letter r8b, r14b, r8d        ;Qr^-1
        right_shift_letter r8b, r13b, r8d       ;Ql
        mov     r8b, [arr_l + r8]               ;L
        left_shift_letter r8b, r13b, r8d        ;Ql^-1
        mov     r8b, [arr_t + r8]               ;T
        right_shift_letter r8b, r13b, r8d       ;Ql
        mov     r8b, [arr_l_rev + r8]           ;L^-1
        left_shift_letter r8b, r13b, r8d        ;Ql^-1
        right_shift_letter r8b, r14b, r8d       ;Qr
        mov     r8b, [arr_r_rev + r8]           ;R^-1
        left_shift_letter r8b, r14b, r8d        ;Qr^-1

        add     r8b, LOW                        ;original value of letter
        mov     [buffer + rbx], r8b             ;modify buffer
        inc     rbx                             ;iterator++
        jmp     encrypt_loop
encrypt_loop_end:
%endmacro
       
_start:
        lea     rbp, [rsp]              ;pointer to number of args 
        call    _check_args             ;valid program arguments
        reverse_perm arr_l, arr_l_rev, ARG_LENGTH ;inverse permutation L
        reverse_perm arr_r, arr_r_rev, ARG_LENGTH ;inverse permutation R
        mov     r13b, [arr_key]                   ;store l value in r13b
        mov     r14b, [arr_key + 1]               ;store r value in r14b
start_loop:
        read_input             
        mov     r12, rax                 ;store  number of read bytes in r12
        encrypt
        print_result
        cmp     qword r12, BUFFER_LENGTH 
        je      start_loop               ;if any text left, continue processing
exit_0:
        mov     eax, SYS_EXIT       
        xor     edi, edi
        syscall
exit_1:
        mov     eax, SYS_EXIT           
        mov     edi, 1
        syscall

_check_args:
        cmp     byte [rbp], ARGC;if number of arguments is invalid - exit 1
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
check_perm_loop:                ;valid program arguments
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

        sub     rcx, 49             ;reduce letter's value to the range of [0, 42)
        cmp     rcx, rax
        je      exit_1              ;1-element cycle is incorrect - exit 1
                                                       
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
        jne     exit_1
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