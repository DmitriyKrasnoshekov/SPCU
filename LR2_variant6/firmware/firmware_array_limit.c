#include "firmware_common.h"

#ifndef ARRAY_SIZE
#define ARRAY_SIZE 30
#endif

void main(void)
{
    // Local array: it is allocated on the stack, so increasing ARRAY_SIZE
    // allows us to experimentally find the memory limit of this firmware.
    volatile int data[ARRAY_SIZE];

    for (int i = 0; i < ARRAY_SIZE; i++)
        data[i] = i * 3 + 7;

    for (int i = 0; i < ARRAY_SIZE; i++) {
        if (data[i] != i * 3 + 7) {
            write_int(GPIO_ADDR, 0);
            write_int(GPIO_ADDR + 4, 0x0000BAD0);
            while (1) { }
        }
    }

    write_int(GPIO_ADDR, ARRAY_SIZE);
    write_int(GPIO_ADDR + 4, 0x00005A5A);

    while (1) { }
}
