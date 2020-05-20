.model tiny

.data
COLOR           equ 4eh
SHADOW_COLOR    equ 1h
VER_CHAR        equ 179
HOR_CHAR        equ 196
UL_CORNER_CHAR  equ 218
UR_CORNER_CHAR  equ 191
DL_CORNER_CHAR  equ 192
DR_CORNER_CHAR  equ 217
SCREEN_WIDTH    equ 80

msg db 'Hello world!$'

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

;=================================================
; MAIN
;=================================================
.code
org 100h
Start:      mov ax, 0b800h
            mov es, ax

            mov ax, 60
            mov bx, 10
            mov cx, 16
            mov dx, 6
            call DrawFrame

            mov ax, 4c00h
            int 21h

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
;-------------------------------------------------
; Spoiling registers: ax, bx, cx, dx, es, di.
;-------------------------------------------------
            mov di, ax
            mov ah, bl
            mov al, SCREEN_WIDTH*2
            mul ah              ; ax = SCREEN_WIDTH*2*y.
            add di, ax          ; Start position: di = x + SCREEN_WIDTH*2*y.

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

            ; Place message.
            NEXT_LINE
            add di, 2*2

            mov ax, offset msg
            mov si, ax
.Message:
            mov al, [si]
            cmp al, '$'
            je .Message_end
            mov es:[di], al
            add di, 2
            inc si
            jmp .Message
.Message_end: ret
DrawFrame ENDP

end Start

