.globl asm_Erase
asm_Erase:
    .intel_syntax noprefix
# rdi = this, rsi = value
    push rdi                # save this
    push rsi                # save value
    add rdi, 24             # rdi = &hash_
    call _ZNKSt4hashIiEclEi # rax = hash_(value)
    pop rsi
    pop rdi
    mov r9, [rdi+8]         # r9 = capacity_
    mov r11,[rdi+16]        # r11 = size_
    xor rdx, rdx
    div r9
    mov rdi, [rdi]
    xor r8, r8              # r8 = inc = 0
# rdi = data_
# rsi = value
# rdx = pos
# r8 = inc
# r9 = capacity_
    .LEraseLoop:
    mov rax, rdx            # rax = pos
    shl rax, 3              # rax *= 8
    mov r10, rdi
    add r10, rax            # r10 = data_ + pos*8
    xor rax, rax            # zero all bits
    mov eax, [r10]          # eax = data_[pos].value
    mov cl, [r10+4]         # cl  = data_[pos].state
    test cl, cl             # data_[pos].state != Item::State::Empty
    jne .LErase1
    xor rax, rax            # return nullptr
    jmp .LEraseEnd
    .LErase1:
    cmp cl, 1
    jne .LErase2
    cmp rax, rsi
    jne .LErase2
    movb [r10+4], 2
    jmp .LEraseEnd
    .LErase2: inc r8
    add rdx, r8
    mov rax, rdx
    xor rdx, rdx
    div r9                  # rdx = pos
    jmp .LEraseLoop

    .LEraseEnd:
    ret

