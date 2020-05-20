#include <cstdio>
#include <cstring>
#include <cassert>
#include <cstdlib>

namespace my {

extern "C" void* memset(void* ptr, int value, size_t num);
extern "C" void* memcpy(void* dst, const void* src, size_t num);
extern "C" void* memchr(void* ptr, int value, size_t num);
extern "C" int   memcmp(const void* ptr1, const void* ptr2, size_t num);

extern "C" size_t strlen (const char* str);
extern "C" char*  strcpy (char* dst, const char* src);
extern "C" char*  strchr (char* str, int character);
extern "C" char*  strrchr(char* str, int character);
extern "C" int    strcmp (const char* str1, const char* str2);

} // namespace my


void TEST_MEMSET() {
    char test[] = "random string for testing";
    char pure[] = "random string for testing";

    my::memset(test, '-', 6);
    my::memset(test + 10, '\n', 3);

    memset(pure, '-', 6);
    memset(pure + 10, '\n', 3);

    assert(strcmp(test, pure) == 0);
    printf("TEST_MEMSET succeed\n");
}

void TEST_MEMCPY() {
    char test[] = "almost very random test message";
    char pure[] = "almost very random test message";
    char copy[] = "random string for testing";

    my::memcpy(test, copy, strlen(copy));

    memcpy(pure, copy, strlen(copy));

    assert(memcmp(test, pure, strlen(copy)) == 0);
    printf("TEST_MEMCPY succeed\n");
}

void TEST_MEMCHR() {
    char str[] = "random string for testing";

    char* test = (char*)my::memchr(str, ' ', 10);
    char* pure = (char*)memchr(str, ' ', 10);
    assert(test == pure);

    test = (char*)my::memchr(test, 'r', 10);
    pure = (char*)memchr(pure, 'r', 10);
    assert(test == pure);

    test = (char*)my::memchr(test, 'r', 10);
    pure = (char*)memchr(pure, 'r', 10);
    assert(test == pure);

    test = (char*)my::memchr(test, 'x', 10);
    pure = (char*)memchr(pure, 'x', 10);
    assert(test == pure);

    printf("TEST_MEMCHR succeed\n");
}

void TEST_MEMCMP() {
    char str1[] = "DWGaOTP12DF0";
    char str2[] = "DWgAOtP12df0";

    assert(my::memcmp(str1, str2, 1) == 0);
    assert(my::memcmp(str1, str2, 2) == 0);
    assert(my::memcmp(str1, str2, 3) < 0);
    assert(my::memcmp(str1 + 3, str2 + 3, 3) > 0);
    printf("TEST_MEMCMP succeed\n");
}

void TEST_STRLEN() {
    char str[] = "random string for testing";
    assert(my::strlen(str) == strlen(str));
    printf("TEST_STRLEN succeed\n");
}

void TEST_STRCPY() {
    char str[] = "random string for testing";
    char test[40];
    char pure[40];

    my::strcpy(test, str);
    strcpy(pure, str);

    assert(strcmp(test, pure) == 0);
    printf("TEST_STRCPY succeed\n");
}


void TEST_STRCHR() {
    char str[] = "random string for testing";

    char* test = my::strchr(str, ' ');
    char* pure = strchr(str, ' ');
    assert(test == pure);

    test = my::strchr(test, 'r');
    pure = strchr(pure, 'r');
    assert(test == pure);

    test = my::strchr(test, 'r');
    pure = strchr(pure, 'r');
    assert(test == pure);

    test = my::strchr(test, 'x');
    pure = strchr(pure, 'x');
    assert(test == pure);

    printf("TEST_STRCHR succeed\n");
}

void TEST_STRRCHR() {
    char str[] = "random string for testing";

    char* test = my::strrchr(str, ' ');
    char* pure = strrchr(str, ' ');
    assert(test == pure);

    test = my::strrchr(test, 's');
    pure = strrchr(pure, 's');
    assert(test == pure);

    test = my::strrchr(test, 's');
    pure = strrchr(pure, 's');
    assert(test == pure);

    test = my::strrchr(test, 'e');
    pure = strrchr(pure, 'e');
    assert(test == pure);

    printf("TEST_STRRCHR succeed\n");
}

void TEST_STRCMP() {
    char str1[] = "DWgaOTP12DF0";
    char str2[] = "DWgaOTP12DF0";
    assert(my::strcmp(str1, str2) == 0);

    char str3[] = "DWGaOTP12DF0";
    char str4[] = "DWgAOtP12df0";
    assert(my::strcmp(str3, str4) < 0);
    assert(my::strcmp(str4, str3) > 0);

    printf("TEST_STRCMP succeed\n");
}

void RunTests() {
    TEST_MEMSET();
    TEST_MEMCPY();
    TEST_MEMCHR();
    TEST_MEMCMP();
    TEST_STRLEN();
    TEST_STRCPY();
    TEST_STRCHR();
    TEST_STRRCHR();
    TEST_STRCMP();
}

int main() {
    RunTests();
    return 0;
}

