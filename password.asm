.186
.model tiny

include string.asm

.data
newline     db 13, 10, '$'
clause      db 'Enter password: $'
fail_msg    db 'Incorrect password.' , 13, 10, '$'
success_msg db 'Welcome!', 13, 10, '$'
alarm       db 'You shall not pass!', 13, 10, '$'

passw_len   db 10
input       db 30 dup(?)
canary1     db 1
password    db 115,60,236,253,132,181,220,21,152,62
canary2     db 1


PRINT MACRO string
            mov ah, 09h
            lea dx, [string]
            int 21h
ENDM

HASH MACRO string
            mov bx, 0
            lea di, [string]
.Loop1:     xor ax, ax
            mov al, [di+bx] ; Load current symbol.
            xor cx, cx
            mov cl, [passw_len]
            dec cx          ; cl = passw_len - 1
            xor dx, dx
.Sum:       add di, cx
            mov dl, [di]
            sub di, cx
            add ax, dx
            loop .Sum
            mov dl, [di]    ; cx = 0
            add ax, dx

            cmp bx, 0
            je .Skip
            mov si, bx
.Loop2:     mov cx, 199
            mul cx
            mov cx, 991
            div cx
            mov ax, dx
            dec si
            cmp si, 0
            jne .Loop2

.Skip:      mov cl, 255
            div cl
            mov [di+bx], ah ; Override current character.

            inc bl
            cmp bl, [passw_len]
            jne .Loop1
ENDM


.code
org 100h
Start:      lea bx, [input]
            mov byte ptr [input], 255

.ReadLoop:  PRINT clause

            mov ah, 0ah
            lea dx, [input]
            int 21h

            PRINT newline

            HASH input+2

            lea di, [input+2]
            lea si, [password]
            xor cx, cx
            mov cl, [passw_len]
            MEMCMP di, si, cx
            cmp ax, 0
            jne .Fail

.Success:   mov al, [canary1]
            add al, [canary2]
            cmp al, 2
            jne .Alarm
            PRINT success_msg
            jmp .ExitProg
.Alarm:     PRINT alarm
            jmp .Alarm
.Fail:      PRINT fail_msg
            jmp .ReadLoop

.ExitProg:  mov ax, 4c00h
            int 21h


end Start

