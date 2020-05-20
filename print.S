#TODO: jump table.


#include <asm/unistd_32.h>  // _64 doesn't work
#include "str.S"

#define STDOUT_FILENO 1

.intel_syntax noprefix

.data
buf_end_ptr:        .quad offset buffer
buffer:             .fill 4096

tmp_buffer:         .fill 100

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
            .irp xmm,xmm7,xmm6,xmm5,xmm4,xmm3,xmm2,xmm1,xmm0
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
        ret
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

                push_args

                mov rsi, rdi            // rsi = current format
                mov rdi, [buf_end_ptr]  // rdi = buffer end
                                        // rax = tmp

.print_loop:                            //  for (;;) {
                call bufferize          //      cur = bufferize(cur);
                cmp rax, 0              //      if (cur == NULL)
                je .print_break         //          break;
                inc rsi                 //      cur++;  // skip %
                mov al, [rsi]           //      char pattern = *cur;
.print_d:       cmp al, 'd'             //      if (pattern == 'd')
                jne .print_x            //          inline_d()
                call inline_d           //
                jmp .print_if_end       //
.print_x:       cmp al, 'x'             //      if (pattern == 'x')
                jne .print_b            //          inline_x()
                call inline_x           //
                jmp .print_if_end       //
.print_b:       cmp al, 'b'             //      else if (pattern == 'b')
                jne .print_f            //          inline_b()
                call inline_b           //
                jmp .print_if_end       //
.print_f:       cmp al, 'f'             //      else if (pattern == 'f')
                jne .print_c            //          inline_f()
                call inline_f           //
                jmp .print_if_end       //
.print_c:       cmp al, 'c'             //      else if (pattern == 'c')
                jne .print_s            //          inline_c()
                call inline_c           //
                jmp .print_if_end       //
.print_s:       cmp al, 's'             //      else if (pattern == 's')
                jne .print_else         //          inline_s()
                call inline_s           //
                jmp .print_if_end       //      else {
.print_else:    call error              //          error();
                jmp .print_break        //          break;
                                        //      }
.print_if_end:  inc rsi                 //      cur++;
                jmp .print_loop         //  } // for loop

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
inline_d:       load_arg_ptr reg
                mov rax, [rax]
                x_to_str eax 10
                tmp_to_buf
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
inline_b:       load_arg_ptr reg
                mov rax, [rax]
                x_to_str eax 2
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
inline_c:       load_arg_ptr reg
                mov rax, [rax]      // rax = char.
                stosb
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
error:          // TODO: raise error
                ret

