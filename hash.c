#include <stdio.h>
#include <string.h>

int main() {
    unsigned char msg[] = "goodhacker";
    int p = 199;
    int mod = 991;
    size_t len = strlen(msg);


    int sum = 0;
    for (size_t k = 0; k < len; ++k) {
      sum += msg[k];
    }

    for (size_t i = 0; i < len; ++i) {
        int ch = msg[i] + sum;
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

