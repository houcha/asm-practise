.186
.model tiny

.data
; Frame config
COLOR           equ 4eh
SHADOW_COLOR    equ 1h
VER_CHAR        equ 179
HOR_CHAR        equ 196
UL_CORNER_CHAR  equ 218
UR_CORNER_CHAR  equ 191
DL_CORNER_CHAR  equ 192
DR_CORNER_CHAR  equ 217
SCREEN_WIDTH    equ 80

;=================================================
; MACROS
;=================================================
DRAW_PIXEL MACRO char
            mov al, char
            stosw
ENDM

NEXT_LINE MACRO
            add di, SCREEN_WIDTH*2
            sub di, bx
            sub di, bx
ENDM

TO_HEX MACRO reg
            LOCAL .number

            add reg, 30h
            cmp reg, '9'
            jle .number
            add reg, 7  ; To 'A' - 'F'.
.number:
ENDM

PRINT_HEX MACRO byte, offset
            mov ah, 0
            mov al, byte
            mov bl, 16

            div bl

            TO_HEX al
            TO_HEX ah

            mov byte ptr es:[di+offset], al
            mov byte ptr es:[di+offset+2], ah
ENDM

PRINT_REG MACRO letter, high, low
            mov byte ptr es:[di], letter
            mov byte ptr es:[di+2], 'x'
            mov byte ptr es:[di+4], ':'
            mov byte ptr es:[di+6], ' '
            push ax bx
            PRINT_HEX high, 8
            PRINT_HEX low, 12
            pop bx ax
            add di, 2*80
ENDM

;=================================================
; MAIN
;=================================================
.code
org 100h
Start:      xor ax, ax
            mov es, ax

            cli                         ; Block other interrupts.
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
            mov Old_08_Ofs, ax
            mov ax, es:[bx+2]
            mov Old_08_Seg, ax

            mov es:[bx], offset New08   ; Set handler offset.
            mov ax, cs                  ; cs = current segment.
            mov es:[bx+2], ax           ; es:[bx] = full address of new handler.
            sti                         ; Allow other interrupts.

            ; http://www.codenet.ru/progr/dos/dos_0052.php
            mov ah, 31h
            mov dx, offset .CodeEnd     ; dx = program end address.
            shr dx, 4                   ; dx /= 16.
            inc dx
            int 21h                     ; Exit.

;=================================================
; FUNCTIONS.
;=================================================
DrawFrame PROC
;-------------------------------------------------
;     Draw a frame with shadow.
;-------------------------------------------------
; Args:
; ax: start_x
; bx: start_y
; cx: length
; dx: height
;
; es: video-memory address
;-------------------------------------------------
; Spoiling registers: ax, bx, cx, dx, di, si.
;-------------------------------------------------
            mov di, ax
            mov ah, bl
            mov al, SCREEN_WIDTH*2
            mul ah              ; ax = SCREEN_WIDTH*2*y.
            add di, ax          ; Start position: di = x + SCREEN_WIDTH*2*y.

            ; Save positions for timer interruption.
            mov ax, di
            add ax, 2*2
            add ax, SCREEN_WIDTH*2
            mov ax_pos, ax

            mov bx, cx          ; bx = length, dx = height.

            mov ah, COLOR       ; Set background color.
            ; Upper left corner.
            DRAW_PIXEL UL_CORNER_CHAR
            ; Upper border.
            sub cx, 2           ; cx = length - 2.
            mov al, HOR_CHAR
            rep stosw
            ; Upper right corner.
            DRAW_PIXEL UR_CORNER_CHAR
            NEXT_LINE

            push dx
            sub dx, 2           ; dx = .Body loop counter = height - 2.

.Body:      DRAW_PIXEL VER_CHAR
            mov cx, bx
            sub cx, 2           ; cx = length - 2.
            mov al, ' '
            rep stosw
            DRAW_PIXEL VER_CHAR
            NEXT_LINE
            dec dx
            cmp dx, 0
            jne .Body

            pop dx              ; dx = height.

            ; Lower left corner.
            DRAW_PIXEL DL_CORNER_CHAR
            ; Lower border.
            mov cx, bx
            sub cx, 2           ; cx = length - 2.
            mov al, HOR_CHAR
            rep stosw
            ; Lower right corner.
            DRAW_PIXEL DR_CORNER_CHAR
            NEXT_LINE

            ; Lower shadow.
            add di, 2*2         ; Shift 2 pixels right.
            mov cx, bx
            sub cx, 2           ; cx = length - 1.
.LowerShadow:
            mov byte ptr es:[di+1], SHADOW_COLOR
            add di, 2
            loop .LowerShadow

            ; Right shadow.
            mov cx, dx
.RightShadow:
            mov byte ptr es:[di+1], SHADOW_COLOR
            mov byte ptr es:[di+3], SHADOW_COLOR
            sub di, SCREEN_WIDTH*2  ; Shift bx up.
            loop .RightShadow

            ret
DrawFrame ENDP

; Keyboard interruption.
New09       PROC
            push ax         ; Save given argument.

            in al, 60h      ; Read button number from keyboard port.


            cmp al, 31      ; Check if button is 's'.
            jne .NotUpdate
            not cs:show_frame ; If s is pressed, change frame state.
                            ; (show->hide and vise versa)

.NotUpdate: pop ax          ; Recover given argument.

            ; Far "dynamic" jmp to base handler.
            db 0eah         ; 0eah is "jmp" code.
Old_09_Ofs  dw 0
Old_09_Seg  dw 0
            ; Pop ip, and flags, for they might be cleared by interruption.
            iret
New09 ENDP

; Timer interruption.
New08       PROC
            push ax bx cx dx di si es

            cmp cs:show_frame, 0
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

.Skip:      pop es si di dx cx bx ax

            ; Far jmp to base handler.
            db 0eah
Old_08_Ofs  dw 0
Old_08_Seg  dw 0
            iret
New08 ENDP


ax_pos          dw 0
show_frame      db 0


.CodeEnd:
end Start

