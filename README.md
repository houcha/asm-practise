# Set
In this task I try to improve set (hash table of ints in open probing) performance via inline assembler.

## 1. Search for weak places
The first and the most essential step to improve set performance is searching for weak places - methods which are the slowest ones.

I use [KCachegrind](http://kcachegrind.sourceforge.net/html/Home.html) for this purpose.

Having tested set on different distributions each of 1 million ints via:

```
g++ test.cpp -O0 -g
```

I got these results:
```
2,656,375,876  PROGRAM TOTALS

--------------------------------------------------------------------------------
           Ir  file:function
--------------------------------------------------------------------------------
1,356,009,401  src/set_int_init.hpp:SetInt::Find(int) const
  574,255,874  src/set_int_init.hpp:SetInt::Insert(int)
  194,843,784  /usr/include/c++/7/bits/functional_hash.h:std::hash<int>::operator()(int) const
   92,276,614  src/set_int_init.hpp:SetInt::Rehash()
```
We can see that `Find` and `Insert` are the most expensive. `std::hash`, which affects both methods and should be optimized too if we want to achieve almost the maximum speed (Note that in this case we should implement our own hash function, for `std::hash` is pretty big and complex...). `Rehash` takes the last position, which means it's rare enough and is not any kind of bottle neck.

From this point I've decided to optimize first two methods, for they do affect set performance.

## 2. Optimizing.
### Find
Let's have a look at `SetInt::Find(int)` code:
```cpp
int* SetInt::Find(int value) const {
  size_t pos = hash_(value) % capacity_;

  for (size_t inc = 0; data_[pos].state != Item::State::Empty;) {
    if (data_[pos].state == Item::State::Filled && data_[pos].value == value) {
      return &data_[pos].value;
    }
    inc += 1;
    pos += inc;
    pos %= capacity_;
  }
  return nullptr;
}
```
`pos` definition is optimal enough, while `for` loop doesn't look so. In fact, every `data` action might cause RAM access, which is heavy instruction (to be honest, it wouldn't access dynamic memory every time because of cache, but it's still a bit more slowly in comparison to register access). Hence, we should save `data_[pos]` in register. Also save `inc` and `pos` as it's almost three extra line, but prevents cache access. Note that loop increase the effect.

This is the way inlined loop looks like:
```cpp
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
```
Intel pre/post-amble makes it a bit longer in comparison to AT&T syntax.
### Insert
Next challenger:
```cpp
void SetInt::Insert(int value) {
  size_t pos = hash_(value) % capacity_;
  ssize_t insert_pos = -1;

  // Don't stop on deleted.
  for (size_t inc = 0; data_[pos].state != Item::State::Empty;) {
    if (data_[pos].state == Item::State::Deleted) {
      insert_pos = pos;
    } else {  // Filled.
      if (data_[pos].value == value) { // Element exists.
        return;
      }
    }
    inc += 1;
    pos += inc;
    pos %= capacity_;
  }

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
```
It's a bit trickier. Initialization and `for` loop are identical to previous method, `if  (insert_pos ==  -1)` left untouched... What about these lines?
```cpp
data_[insert_pos].value = value;
data_[insert_pos].state = Item::State::Filled;
```
One may think since it is machine word long, we can place it into a register, which is to be stored only once. However, since `data_[insert_pos]` is to be placed in cache line, one extra cache access is negligible thing.

The last part uses xmm registers. In fact, there is no sense to optimize it, for we will merely call the same xmm functions as compiler calls. Though there is one possible way to optimize it. Condition `size_ > capacity_ * LOAD_FACTOR_` might be a success only if we've inserted element into an empty (not deleted) cell. Thus, we can make a kind of flag, which shows whether previous `if` has been entered or not, and skip xmm block if necessary. Seems worth, yet the fact that we have to start inline since previous `if`... This way, the whole method would be inline, but it is hardly ever the thing inline assembler is used for.

## 3. Result
Having optimized loops in both methods, I've got next results:
```
2,213,170,144  PROGRAM TOTALS

--------------------------------------------------------------------------------
         Ir  file:function
--------------------------------------------------------------------------------
961,409,215  src/set_int_inl.hpp:SetInt::Find(int) const
520,967,226  src/set_int_inl.hpp:SetInt::Insert(int)
194,843,784  /usr/include/c++/7/bits/functional_hash.h:std::hash<int>::operator()(int) const
 92,276,614  src/set_int_inl.hpp:SetInt::Rehash()
```
Visualize it in a table.
|                |Find     |Insert      |
|----------------|---------|------------|
|ir boost in %   |41       |10          |
|lines count     |26       |27          |
|factor          |1,57     |0,37        |

**Genaral boost is 20%**

## Bonus
I've additionally implemented both methods in pure .S asm (see `src/asm_impl/`) in order to compare the effectiveness of such approach with inline assembler.

There is an output:
```
1,528,585,396  PROGRAM TOTALS

--------------------------------------------------------------------------------
         Ir  file:function
--------------------------------------------------------------------------------
565,409,215  src/asm_impl/find.S:0x000000000000139b
194,843,944  /usr/include/c++/7/bits/functional_hash.h:std::hash<int>::operator()(int) const
236,816,382  src/asm_impl/insert.S:0x00000000000013e2
 92,276,814  src/set_int_asm.hpp:SetInt::Rehash()
```
|                |Find     |Insert      |
|----------------|---------|------------|
|ir boost in %   |149      |143         |
|lines count     |30       |55          |
|factor          |5,0      |2,6         |

**Genaral boost is 74%**

## Final bonus
Yet 74% sounds amazing, there is still one thing that makes matchwood of all my efforts...

Its name is -O3.

```
g++ test.cpp -O3 -g
```
**Disclaimer: not for the faint-hearted!**
```
804,105,269  PROGRAM TOTALS

--------------------------------------------------------------------------------
         Ir  file:function
--------------------------------------------------------------------------------
???
179,177,007  src/set_int_init.hpp:SetInt::Rehash()
???
```
|                |Find     |Insert     |
|----------------|---------|-----------|
|ir boost in %   |>0       |>0         |
|lines count     |0        |0          |
|factor          |∞        |∞          |

**Genaral boost is 220%**
