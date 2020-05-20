#include <stdio.h>

extern void print(const char *format, ...);

int main()
{
    print(
        "First numbers: %d %f %d %f %d %f %d %f %d %f %d %f\n"
        "Some string: %s\n"
        "More numbers: %d %f %d %f %d %f %d %f %d %f %d %f\n"
        "Test precision: %f %f %f\n"
        "Hex: %x %x %x\n"
        "Chars: %c %c %c %c\n"
        "Binary: %b\n",
        1, 1.0, -2, -2.0, 3, 3.0, -4, -4.0, 5, 5.0, -6, -6.0,
        "string expanded from %s",
        7, 7.0, -8, -8.0, 9, 9.0, -10, -10.0, 11, 11.0, -12, -12.0,
        1.12, 1.1234, 1.12345678,
        0xfffac, 0x011d, 0xfffffff,
        'c', 'h', 'a', 'r',
        0xf771
        );

    return 0;
}

