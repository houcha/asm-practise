//=================================================
// STR* INTRINSICS
//=================================================

.intel_syntax noprefix

.text
//*************************************************
// size_t strlen(const char* str)
//*************************************************
// ARGS: rdi - str
// Spoil registers: rax, rcx, rdi
//*************************************************
.global strlen
strlen: xor al, al
        xor rcx, rcx    // rcx = 0.
        not rcx         // rcx = -1 = Max.
        cld
        repne scasb
        // Now rcx = -1 - strlen - 1(because \0 is not counted in str len)
        // rcx = -strlen - 2.
        not rcx         // rcx = strlen + 1.
        dec rcx         // rcx = strlen.
        mov rax, rcx    // return strlen.
        ret

//*************************************************
// char* strcpy(char* dst, const char* src)
//*************************************************
// ARGS: rdi - dst
//       rsi - src
// Spoil registers: rdx.
//*************************************************
.global strcpy
strcpy:         mov rdx, rdi    // Save dst in rdx.
                cld
strcpy.loop:    lodsb           // al = rdi[i].
                stosb           // rsi[i] = al.
                cmp al, 0
                jne strcpy.loop // If al != 0 then continue.
                mov rax, rdx    // dst is returned.
                ret

//*************************************************
// char* strchr(char* str, int character)
//*************************************************
// ARGS: rdi - str
//       rsi - value
// Spoil registers: rdi = rax
//*************************************************
.global strchr
strchr:         mov rax, rsi
                cld
strchr.loop:    scasb           // al - [rdi].
                jz strchr.break // Value is found.
                cmpb [rdi], 0   // Check for str end.
                je strchr.null  // Value is not found in a string.
                jmp strchr.loop
strchr.break:   dec rdi         // rdi points to first non-al, decrement it.
                mov rax, rdi
                ret
strchr.null:    mov rax, 0
                ret

//*************************************************
// char* strrchr(char* str, int character)
//*************************************************
// ARGS: rdi - str
//       rsi - value
// Spoil registers: rbx.
//*************************************************
.global strrchr
strrchr:        mov rax, rsi
                mov rbx, 0          // rbx = address of last found value.
                cld
strrchr.loop:   scasb               // al - [rdi].
                jnz strrchr.skip    // If value is not found, skip rbx update.
                mov rbx, rdi        // Else update rbx.
strrchr.skip:   cmpb [rdi], 0
                jne strrchr.loop    // Continue while \0 is not found.
                cmp rbx, 0
                je strrchr.null     // No value is found.
                dec rbx             // rbx points to first non-al, increment it.
                mov rax, rbx        // Else return last found value address.
                ret
strrchr.null:   mov rax, 0
                ret

//*************************************************
// int strcmp(const char* str1, const char* str2)
//*************************************************
// ARGS: rdi - str1
//       rsi - str2
// Spoil registers: rdi, rsi.
//*************************************************
.global strcmp
strcmp:         cld
strcmp.loop:    cmpsb
                jnz strcmp.break    // [rdi] != [rsi] => break.
                cmpb [rdi], 0
                je strcmp.equal
                jmp strcmp.loop
strcmp.break:   jns strcmp.less     // SF = 1 => str1 - str2 < 0 => str1 < str2.
                mov rax, 1          // Greater.
                ret
strcmp.less:    mov rax, -1
                ret
strcmp.equal:   mov rax, 0
                ret

