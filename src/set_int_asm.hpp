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


#endif // HASH_TABLE_INT_HPP

