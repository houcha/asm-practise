.globl _ZN6SetInt6InsertEi
_ZN6SetInt6InsertEi:
.intel_syntax noprefix
# rdi = this, rsi = value
    add rdi, 24             # rdi = &hash_
    call _ZNKSt4hashIiEclEi # rax = hash_(value)
    sub rdi, 24
    mov r9, [rdi+8]         # r9 = capacity_
    xor rdx, rdx
    div r9
    mov r11, rdi
    mov rdi, [rdi]
    xor r8, r8              # r8 = inc = 0
    mov r10, -1             # r10 = insert_pos = -1
# rdi = data_
# rsi = value
# rdx = pos
# r8 =  inc
# r9 =  capacity_
# r10 = insert_pos
# r11 = this

.LInsertLoop:
    lea rax, [rdi+rdx*8]    # rax = &data_[pos]
    mov cl, [rax+4]
    test cl, cl             # data_[pos].state ? Item::State::Empty
    je .LInsert3
    cmp cl, 2               # data_[pos].state ? Item::State::Deleted
    jne .LInsert1
    mov r10, rdx
    jmp .LInsert2
.LInsert1:
    cmp [rax], esi
    jne .LInsert2
    jmp .LInsertEnd
.LInsert2:
    inc r8
    add rdx, r8
    mov rax, rdx
    xor rdx, rdx
    div r9                  # rdx = pos
    jmp .LInsertLoop

.LInsert3:
    cmp r10, -1
    jne .LInsert4
    mov r10, rdx
    incq [r11+16]

.LInsert4:
    lea rax, [rdi+r10*8]
    mov [rax], esi          # data_[insert_pos].value = value
    movb [rax+4], 1         # data_[insert_pos].state = Item::State::Filled
    cvtsi2sd xmm0, r9       # xmm0 = capacity_
    movsd xmm1, QWORD PTR .LLoadFactor[rip]
    mulsd xmm0, xmm1
    cvtsd2si rax, xmm0
    cmp [r11+16], rax
    jle .LInsertEnd
    mov rdi, r11
    call  _ZN6SetInt6RehashEv
    jmp .LInsertEnd

.LLoadFactor:
    .long 2576980378
    .long 1072273817

.LInsertEnd:
    ret

