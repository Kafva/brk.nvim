// cc -O0 -g main.c && gdb a.out
#include <stdio.h>

int main(int argc, char *argv[], char *envp[]) {

    for (int i = 0; i < 10; i++) {
        printf("%d\n", i);
    }

    return 0;
}
