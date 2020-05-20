#include <asm/unistd_32.h>  // _64 doesn't work
#include "str.S"

#define STDOUT_FILENO 1

.intel_syntax noprefix

.data
buf_end_ptr:        .quad offset buffer
buffer:             .fill 4096

jump_table:         .fill ('z' - 'a')*8
table_filled:       .byte 0

tmp_buffer:         .fill 1000

pushed_args_ptr:    .quad 0

reg_args_ptr:       .quad 0
reg_args_cnt:       .byte 0

xmm_args_ptr:       .quad 0
xmm_args_cnt:       .byte 0

precision:          .byte 11    // Number of digits to be displayed on float.
//-----------------------------------------------------------------------------
//
// MACROS
//
//-----------------------------------------------------------------------------
.altmacro
.macro fill_jump_table
        LOCAL .loop
        push rax
        push rcx
        push rdi

        // Fill with default.
        lea rax, do_nothing
        mov rcx, 'x' - 'b'
        lea rdi, jump_table
        cld
        rep stosq

        lea rdi, jump_table

        lea rax, inline_b
        mov [rdi+('b'-'a')*8], rax
        lea rax, inline_c
        mov [rdi+('c'-'a')*8], rax
        lea rax, inline_d
        mov [rdi+('d'-'a')*8], rax
        lea rax, inline_f
        mov [rdi+('f'-'a')*8], rax
        lea rax, inline_s
        mov [rdi+('s'-'a')*8], rax
        lea rax, inline_x
        mov [rdi+('x'-'a')*8], rax
        // via .irp ??? Next don't work :(
        //.irp letter, b,c,d,f,s,x
        //lea rax, inline_\letter
        //mov [rdi+('\letter' - 'a')*8], rax
        //.endr

        movb table_filled, 1

        pop rdi
        pop rcx
        pop rax
.endm

// Print tramplin.
.macro push_args
            add rsp, 8*2                // Through call print.
            mov pushed_args_ptr, rsp
            sub rsp, 8*2
            // Push regs.
            .irp reg,r9,r8,rcx,rdx,rsi
            push reg
            .endr
            mov reg_args_ptr, rsp
            movb reg_args_cnt, 5
            // Push xmm.
            .irp xmm, xmm7,xmm6,xmm5,xmm4,xmm3,xmm2,xmm1,xmm0
            sub rsp, 8
            movsd [rsp], xmm
            .endr
            mov xmm_args_ptr, rsp
            mov xmm_args_cnt, al
.endm

// Convert x to 'base' base char (e.g. 0 -> '0', 10 -> 'A').
.macro x_to_base x base
            LOCAL .letter, .end
            cmp x, 9
            jg .letter
            add x, '0'
            jmp .end
.letter:    add x, 87
.end:
.endm

// x = *ax register contains number to be converted to string.
// return pointer to tmp_buffer end.
.macro x_to_str x base
        LOCAL .loop

        push rbx
        lea rbx, tmp_buffer

        mov rcx, base
        cmp x, 0
        jge .loop
        movb [rdi], '-'
        inc rdi
        neg x
.loop:  xor rdx, rdx
        div rcx         // rax = 0:rax / 10; rdx = 0:rax % 10
        x_to_base dl base
        mov [rbx], dl
        inc rbx
        cmp rax, 0
        jne .loop

        dec rbx
        mov rax, rbx    // Ptr to first digit.

        pop rbx
.endm

// Load (regname)_args_ptr to rax.
// If (regname)_args_ptr == 0, loads from pushed_args_ptr.
.macro load_arg_ptr regname
        LOCAL .zero, .end

        cmpb regname&_args_cnt, 0
        je .zero
        mov rax, regname&_args_ptr
        addq regname&_args_ptr, 8
        decb regname&_args_cnt
        jmp .end
.zero:  mov rax, pushed_args_ptr
        addq pushed_args_ptr, 8
.end:
.endm

// check_macro is macro to be invoked on every loop iteration of copy.
.macro tmp_to_buf check_macro
        LOCAL .loop
        mov rcx, rax
        sub rcx, offset tmp_buffer
        inc rcx
.loop:  check_macro
        mov dl, [rax]
        mov [rdi], dl
        inc rdi
        dec rax
        loop .loop
.endm
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
.text
//*************************************************
// void print(const char *format, ...)
//*************************************************
// ARGS:
// rax = number of float args
// rdi = format
// rsi - r9d = int args
// xmm = float args
// stack = rest
//*************************************************
.global print
print:          push rbp
                mov rbp, rsp

                cmpb table_filled, 0
                jne .skip_filling
                fill_jump_table

.skip_filling:  push_args

                mov rsi, rdi
                mov rdi, [buf_end_ptr]
                // rsi = current format
                // rdi = buffer end
                // rax = tmp
.print_loop:    call bufferize          // read to buffer
                cmp rax, 0              // if (cur == NULL)
                je .print_break         //          break;
                inc rsi                 //      cur++;  // skip %
                xor rax, rax
                mov al, [rsi]           //      char pattern = *cur;
                sub rax, 'a'
                shl rax, 3              // *= 8
                lea rcx, jump_table
                add rcx, rax
                mov rcx, [rcx]

                call rcx

                inc rsi
                jmp .print_loop

.print_break:   mov rsp, rbp
                pop rbp
                mov [buf_end_ptr], rdi
                ret


//*************************************************
// None of these functions spoils rdi and rsi.
//*************************************************

bufferize:          cld
.bufferize_loop:    mov al, [rsi]           // Load current format symbol in al.

                    cmp al, '%'
                    je .bufferize_pattern   // %(pattern) is met.

                    movsb                   // buffer[i] = format[i]; ++i

                    cmp al, 0
                    je .bufferize_null      // \0 is met.

                    cmp al, '\n'
                    jne .bufferize_loop     // \n is met.
                    call flush

                    jmp .bufferize_loop

.bufferize_pattern: ret
.bufferize_null:    mov rax, 0
                    ret

flush:  push rbx

        mov rax, __NR_write
        mov rbx, STDOUT_FILENO
        lea rcx, buffer
        mov rdx, rdi            // rdi == buffer end
        sub rdx, offset buffer
        int 0x80

        lea rdi, buffer         // rdi = buffer begin

        pop rbx
        ret
//-----------------------------------------------------------------------------
//
// INLINES.
//
//-----------------------------------------------------------------------------
inline_b:       load_arg_ptr reg
                mov rax, [rax]

                lea rcx, tmp_buffer
.loop_inl_b:    mov dl, al
                and dl, 1
                add dl, '0'
                mov [rcx], dl
                shr rax, 1
                inc rcx
                cmp rax, 0
                jne .loop_inl_b

                dec rcx
                mov rax, rcx    // Ptr to first digit.

                tmp_to_buf
                ret
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
inline_c:       load_arg_ptr reg
                mov rax, [rax]      // rax = char.
                stosb
                ret
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
inline_d:       load_arg_ptr reg
                mov rax, [rax]
                x_to_str eax 10
                tmp_to_buf
                ret
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
// check_macro, which tries to insert float-point on rcx == precision.
.macro try_insert_dot
        cmp cl, precision
        jne .skip
        movb [rdi], '.'
        inc rdi
        dec rcx
.skip:
.endm

inline_f:       load_arg_ptr xmm
                movsd xmm0, [rax]
                mov rax, 10
                cvtsi2sd xmm1, rax
                // Multiply xmm0 by 10^precision.
                mov rcx, precision
.inline_f_mul:  mulsd xmm0, xmm1
                loop .inline_f_mul

                cvtsd2si rax, xmm0

                x_to_str rax 10
                tmp_to_buf try_insert_dot
                ret
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
inline_s:       load_arg_ptr reg
                mov rax, [rax]      // rax = ptr to string.
                mov rcx, rsi        // Save rsi.
                mov rsi, rax        // rsi = src.
                call strcpy
                mov rsi, rcx        // Recover rsi.
                ret
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
inline_x:       load_arg_ptr reg
                mov rax, [rax]
                x_to_str eax 16
                tmp_to_buf
                ret
//-----------------------------------------------------------------------------
//
//
//-----------------------------------------------------------------------------
do_nothing:     ret

