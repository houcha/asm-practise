#include <stddef.h> //size_t

extern void* memset(void* ptr, int value, size_t num);
extern void* memcpy(void* dst, const void* src, size_t num);
extern void* memchr(void* ptr, int value, size_t num);
extern int   memcmp(const void* ptr1, const void* ptr2, size_t num);

