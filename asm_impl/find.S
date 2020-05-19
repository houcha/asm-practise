.globl _ZNK6SetInt4FindEi
_ZNK6SetInt4FindEi:
    .intel_syntax noprefix
# rdi = this, rsi = value
    add rdi, 24             # rdi = &hash_
    call _ZNKSt4hashIiEclEi # rax = hash_(value)
    sub rdi, 24
    mov r9, [rdi+8]        # r9 = capacity_
    xor rdx, rdx
    div r9
    mov rdi, [rdi]
    xor r8, r8            # r8 = inc = 0
# rdi = data_
# rsi = value
# rdx = pos
# r8 = inc
# r9 = capacity_
    .LFindLoop:
    lea rax, [rdi+rdx*8]    # rax = &data_[pos]
    mov cl, [rax+4]
    test cl, cl             # data_[pos].state ? Item::State::Empty
    jne .LFind1
    xor rax, rax            # return nullptr
    ret
    .LFind1:
    cmp cl, 1
    jne .LFind2
    cmp [rax], esi
    jne .LFind2
    ret                     # return &data_[pos]
    .LFind2:
    inc r8
    add rdx, r8
    mov rax, rdx
    xor rdx, rdx
    div r9                  # rdx = pos
    jmp .LFindLoop

