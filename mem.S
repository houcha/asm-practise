//=================================================
// MEM* INTRINSICS
//=================================================

.intel_syntax noprefix
.text

//*************************************************
// void* memset(void* ptr, int value, size_t num)
//*************************************************
// ARGS: rdi = ptr
//       rsi = value
//       rdx = num
// Spoil registers: rcx.
//*************************************************
.global memset
memset: mov rcx, rdx
        mov rdx, rdi    // Save ptr in rdx.
        mov rax, rsi
        cld             // direction Flag = 0.
        rep stosb       // al -> [rdi] && rdi++ in loop.
        mov rax, rdx    // ptr is returned.
        ret

//*************************************************
// void* memcpy(void* dst, const void* src, size_t num)
//*************************************************
// ARGS: rdi = dst
//       rsi = src
//       rdx = num
// Spoil registers: rax, rcx, rdi = dst + num, rsi = src + num.
//*************************************************
.global memcpy
memcpy: mov rcx, rdx
        mov rdx, rdi    // Save dst in rdx.
        cld
        rep movsb
        mov rax, rdx    // dst is returned.
        ret

//*************************************************
// void*  memchr(void* ptr, int value, size_t num)
//*************************************************
// ARGS: rdi = ptr
//       rsi = value
//       rdx = num
// Spoil registers: rcx.
//*************************************************
.global memchr
memchr:         mov rax, rsi
                mov rcx, rdx
                cld
                repne scasb     // Find non-al byte starting at es:[rdi].
                jnz memchr.null // If char is not found.
                dec rdi         // rdi points to first non-al, decrement it.
                mov rax, rdi    // char pos is returned.
                ret
memchr.null:    mov rax, 0
                ret

//*************************************************
// int memcmp(const void* ptr1, const void* ptr2, size_t num)
//*************************************************
// ARGS: rdi = ptr1
//       rsi = ptr2
//       rdx = num
// Spoil registers: rcx.
//*************************************************
.global memcmp
memcmp:         mov rcx, rdx
                cld
                repe cmpsb
                jz memcmp.equal // Mems are equal.
                jns memcmp.less // If SF = 0 then rsi - rdi => ptr1 < ptr2.
                mov rax, 1      // Greater.
                ret
memcmp.less:    mov rax, -1
                ret
memcmp.equal:   mov rax, 0
                ret

