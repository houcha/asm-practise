#ifndef HASH_TABLE_INT_HPP
#define HASH_TABLE_INT_HPP

#include <new>        // Placement new.
#include <functional> // std::hash

/**
 * SetInt with quadratic probing.
 */
class SetInt {
  public:
    explicit SetInt(size_t capacity = 16);
    SetInt(const SetInt& other);
    SetInt(SetInt&& other);
    SetInt& operator=(const SetInt& other);
    SetInt& operator=(SetInt&& other);
    ~SetInt();

    void Insert(int value);
    void Erase (int value);
    int* Find  (int value) const;

  private:
    struct Item;

    void Rehash();

  private:
    Item* data_;

    size_t capacity_;
    size_t size_;

    std::hash<int> hash_;

    constexpr static double LOAD_FACTOR_ = 0.8;
    constexpr static size_t REHASH_FACTOR_ = 2;
};


struct SetInt::Item {
    int  value;
    char state;

    enum State : char {
      Empty,
      Filled,
      Deleted
    };

    Item()
        : value(),
          state(Empty) {}

    explicit Item(int item)
        : value(item),
          state(Filled) {}
};



SetInt::SetInt(size_t capacity)
    : capacity_(capacity),
      size_(0),
      data_(new Item [capacity])
{
}


SetInt::SetInt(const SetInt& other)
    : capacity_(other.capacity_),
      size_(other.size_),
      data_(new Item [other.capacity_])
{
  for (size_t i = 0; i < other.capacity_; ++i) {
    new (data_ + i) Item(other.data_[i]);
  }
}


SetInt::SetInt(SetInt&& other)
    : capacity_(other.capacity_),
      size_(other.size_),
      data_(other.data_)
{
  other.capacity_ = 0;
  other.size_ = 0;
  other.data_ = nullptr;
}


SetInt& SetInt::operator=(const SetInt& other) {
  capacity_ = other.capacity_;
  size_ = other.size_;

  delete [] data_;

  data_ = new Item [other.capacity_];
  for (size_t i = 0; i < other.capacity_; ++i) {
    new (data_ + i) Item(other.data_[i]);
  }
}


SetInt& SetInt::operator=(SetInt&& other) {
  capacity_ = other.capacity_;
  size_ = other.size_;
  data_ = other.data_;

  other.capacity_ = 0;
  other.size_ = 0;
  other.data_ = nullptr;
}

SetInt::~SetInt() {
  delete [] data_;
}

void SetInt::Rehash() {
  SetInt new_table(capacity_ * REHASH_FACTOR_);

  for (size_t i = 0; i < capacity_; ++i) {
    if (data_[i].state == Item::State::Filled) {
      new_table.Insert(data_[i].value);
    }
  }

  *this = std::move(new_table);
}

void SetInt::Insert(int value) {
  size_t pos = hash_(value) % capacity_;
  ssize_t insert_pos = -1;

  __asm__(
"    .intel_syntax noprefix\n\t"
"    xor r8, r8\n"
"    mov r9, rcx\n"
"    mov r10, rax\n"
".LInsertLoop:\n"
"    lea rax, [rdi+rdx*8]    # rax = &data_[pos]\n"
"    mov cl, [rax+4]\n"
"    test cl, cl             # data_[pos].state ? Item::State::Empty\n"
"    je .LInsertBreak\n"
"    cmp cl, 2               # data_[pos].state ? Item::State::Deleted\n"
"    jne .LInsert1\n"
"    mov r10, rdx\n"
"    jmp .LInsert2\n"
".LInsert1:\n"
"    cmp [rax], esi\n"
"    jne .LInsert2\n"
"    jmp .LInsertRet\n"
".LInsert2:\n"
"    inc r8\n"
"    add rdx, r8\n"
"    mov rax, rdx\n"
"    xor rdx, rdx\n"
"    div r9                  # rdx = pos\n"
"    jmp .LInsertLoop\n"

".LInsertRet:\n"
"    mov rsp, rbp\n"
"    pop rbp\n"
"    ret\n"

".LInsertBreak:\n"
"      mov rax, r10\n"
"      .att_syntax\n"
      : "=d"(pos), "=a"(insert_pos)
      : "D"(data_), "S"(value), "a"(insert_pos), "d"(pos), "c"(capacity_)
      : "r8", "r9", "r10");

  if (insert_pos == -1) {
    insert_pos = pos;
    size_++;
  }

  data_[insert_pos].value = value;
  data_[insert_pos].state = Item::State::Filled;

  if (size_ > capacity_ * LOAD_FACTOR_) {
    Rehash();
  }
}

void SetInt::Erase(int value) {
  size_t pos = hash_(value) % capacity_;

  for (size_t inc = 0; data_[pos].state != Item::State::Empty;) {
    if (data_[pos].state == Item::State::Filled &&
        data_[pos].value == value) {
      data_[pos].state = Item::State::Deleted;
      break;
    }
    inc += 1;
    pos += inc;
    pos %= capacity_;
  }
}

int* SetInt::Find(int value) const {
  size_t pos = hash_(value) % capacity_;

  __asm__ __volatile__(
"    .intel_syntax noprefix\n"
"    xor r8, r8	             # r8 = inc\n"
"    mov r9, rcx             # r9 = capacity_\n"

".LFindLoop:\n"
"    lea rax, [rdi+rdx*8]    # rax = &data_[pos]\n"
"    mov cl, [rax+4]\n"
"    test cl, cl             # data_[pos].state ? Item::State::Empty\n"
"    jne .LFind1\n"
"    xor rax, rax            # return nullptr\n"
"    jmp .LFindRet           # return &data_[pos]\n"
".LFind1:\n"
"    cmp cl, 1\n"
"    jne .LFind2\n"
"    cmp [rax], esi\n"
"    jne .LFind2\n"
"    jmp .LFindRet           # return &data_[pos]\n"
".LFind2:\n"
"    inc r8\n"
"    add rdx, r8\n"
"    mov rax, rdx\n"
"    xor rdx, rdx\n"
"    div r9                  # rdx = pos\n"
"    jmp .LFindLoop\n"

".LFindRet:\n"
"    mov rsp, rbp\n"
"    pop rbp\n"
"    ret\n"
"    .att_syntax\n"
    :
    : "D"(data_), "S"(value), "d"(pos), "c"(capacity_)
    :);
}



#endif // HASH_TABLE_INT_HPP

