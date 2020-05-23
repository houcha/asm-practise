#include <stdio.h>
#include <string.h>

int main() {
    unsigned char msg[] = "1111111111";
    int p = 199;
    int mod = 991;
    size_t len = strlen(msg);



    for (size_t i = 0; i < len; ++i) {
        int ch = msg[i];
        for (size_t k = 0; k < len; ++k) {
          ch += msg[k];
        }
        for (size_t j = 0; j < i; ++j) {
            ch *= p;
            ch %= mod;
        }
        msg[i] = ch % 255;
        printf("%d ", msg[i]);
    }
    printf("\n");
    return 0;
}

