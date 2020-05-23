.model tiny

;=================================================
; MACROS
;=================================================
MEMSET MACRO ptr, value, num
;-------------------------------------------------
; Spoil registers: cx, di.
;-------------------------------------------------
        mov di, ptr
        mov al, value
        mov cx, num
        cld         ; Direction Flag = 0.
        rep stosb
        mov ax, ptr ; ptr is returned.
ENDM

MEMCPY MACRO dst, src, num
;-------------------------------------------------
; Spoil registers: cx, di, si.
;-------------------------------------------------
        mov di, dst
        mov si, src
        mov cx, num
        cld
        rep movsb
        mov ax, dst ; dst is returned.
ENDM

MEMCHR MACRO ptr, value, num
;-------------------------------------------------
; Spoil registers: cx, di.
;-------------------------------------------------
        mov di, ptr
        mov al, value
        mov cx, num
        cld
        repne scasb
        jnz .Null   ; If char is not found.
        mov ax, di  ; char pos is returned.
        jmp .Return
.Null:  mov ax, 0
.Return:
ENDM

MEMCMP MACRO ptr1, ptr2, num
;-------------------------------------------------
; Spoil registers: cx, si, di.
;-------------------------------------------------
        mov di, ptr1
        mov si, ptr2
        mov cx, num
        cld
        repe cmpsb
        jz .Equal   ; Mems are equal.
        js .Less    ; If SF = 1 then ptr1 - ptr2 < 0, so ptr1 < ptr2.
        mov ax, 1   ; Greater.
        jmp .Return
.Less:  mov ax, -1
        jmp .Return
.Equal: mov ax, 0
.Return:
ENDM

STRLEN MACRO str
;-------------------------------------------------
; Spoil registers: cx, di.
;-------------------------------------------------
        mov di, str
        xor al, al
        xor cx, cx      ; cx = 0.
        not cx          ; cx = -1 = MAX.
        cld
        repne scasb
        ; Now cx = -1 - strlen - 1(because \0 is not counted in str len) = -strlen - 2.
        not cx      ; cx = strlen + 1.
        dec cx      ; cx = strlen.
        mov ax, cx  ; return strlen.
ENDM

STRCPY MACRO dst, src
;-------------------------------------------------
; Spoil registers: di, si.
;-------------------------------------------------
        mov di, dst
        mov si, src
        cld
.Loop:  lodsb       ; al = di[i].
        stosb       ; si[i] = al.
        cmp al, '$'
        jne .Loop   ; If al != $ then continue.
.Return:mov ax, dst ; dst is returned.
ENDM

STRCHR MACRO str, value
;-------------------------------------------------
; Spoil registers: di.
;-------------------------------------------------
        mov di, str
        mov al, value
        cld
.Loop:  scasb
        jz .Break       ; Value is found.
        cmp byte ptr [di], '$'
        je .Null        ; Value is not found in a string.
        jmp .Loop
.Break: mov ax, di
        jmp .Return
.Null:  mov ax, 0
.Return:
ENDM

STRRCHR MACRO str, value
;-------------------------------------------------
; Spoil registers: bx, di.
;-------------------------------------------------
        mov di, str
        mov al, value
        mov bx, 0       ; bx = address of last found value.
        cld
.Loop:  scasb
        jnz .Skip       ; If value is not found, skip bx update.
        mov bx, di      ; Else update bx.
.Skip:  cmp byte ptr [di], '$'
        jne .Loop       ; Continue while $ is not found.
        cmp bl, 0
        je .Null        ; No value is found.
        mov ax, bx      ; Else return last found value address.
        jmp .Return
.Null:  mov ax, 0
.Return:
ENDM

STRCMP MACRO str1, str2
;-------------------------------------------------
; Spoil registers:
;-------------------------------------------------
        mov di, str1
        mov si, str2
        cld
.Loop:  cmpsb
        jnz .Break  ; If [di] != [si] then break.
        cmp byte ptr [di], '$'
        je .Equal
        jmp .Loop
.Break: js .Less    ; If SF = 1 then str1 - str2 < 0, so str1 < str2.
        mov ax, 1   ; Greater.
        jmp .Return
.Less:  mov ax, -1
        jmp .Return
.Equal: mov ax, 0
.Return:
ENDM

