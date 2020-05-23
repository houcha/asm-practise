# Frame with registers

This is an interruption-based frame written in Turbo Assembler in DOS OS.
## How it works
As the program starts, a default 8-th (timer) and 9-th (keyboard) interrupt handlers are replaced with `New08` and `New09` handlers respectively:

```asm
            cli							            ; Block other interrupts.
            ; Save old 9th handler.
            mov bx, 9*4
            ; es:[bx] = FFFF(offset):FFFF(segment)
            mov ax, es:[bx]             ; Save old handler offset.
            mov Old_09_Ofs, ax
            mov ax, es:[bx+2]           ; Save old handler segment.
            mov Old_09_Seg, ax

            mov es:[bx], offset New09   ; Set handler offset.
            mov ax, cs                  ; cs = current segment.
            mov es:[bx+2], ax           ; es:[bx] = full address of new handler.

            ; Save old 8th handler.
            mov bx, 8*4
            mov ax, es:[bx]
            mov Old08Ofs, ax
            mov ax, es:[bx+2]
            mov Old08Seg, ax

            mov es:[bx], offset New08   ; Set handler offset.
            mov ax, cs                  ; cs = current segment.
            mov es:[bx+2], ax           ; es:[bx] = full address of new handler.
            
            sti							            ; Allow other interrupts.
```
I save old (default) handler segment and offset to be able to call them from new handlers. Otherwise, timer and keyboard will go dead.

There is a `New09`, which simply switches frame state if `s` button has been pressed:
```asm
New09       PROC
            push ax			    ; Save given argument.

            in al, 60h      ; Read button number from keyboard port.

            
            cmp al, 31		  ; Check if button is 's'.
            jne .NotUpdate
            not show_frame	; If s is pressed, change frame state.
				                    ; (show->hide and vise versa)

.NotUpdate: pop ax          ; Recover given argument.

            ; Far "dynamic" jmp to base handler.
            db 0eah			    ; 0eah is "jmp" code.
Old_09_Ofs  dw 0
Old_09_Seg  dw 0
            ; Pop ip, and flags, for they might be cleared by interruption.
            iret
New09 ENDP
```
Timer handler is invoked every timer tick. It checks whether `show_frame` flag is set and, if one is set, draw a frame with dumped registers in hex:
```asm
New08       PROC
            push ax bx cx dx di si es	; Save arguments to pass them to a base handler.
                                      ; See DrawFrame description -> spoiling registers. 

            cmp show_frame, 0
            ; See https://stackoverflow.com/questions/39427980/relative-jump-out-of-range-by
            jne .Show
            jmp .Skip

.Show:      mov di, 0b800h
            mov es, di

            push ax bx cx dx
            mov ax, 32
            mov bx, 10
            mov cx, 16
            mov dx, 6
            call DrawFrame
            pop dx cx bx ax

            mov di, ax_pos
            PRINT_REG 'a', ah, al
            PRINT_REG 'b', bh, bl
            PRINT_REG 'c', ch, cl
            PRINT_REG 'd', dh, dl

.Skip:      pop es si di dx cx bx ax	; Recover handler arguments.

            ; Far jmp to base handler.
            db 0eah
Old08Ofs    dw 0
Old08Seg    dw 0
            iret
New08 ENDP
```
## Look
