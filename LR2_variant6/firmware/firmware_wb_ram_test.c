#include "firmware_common.h"

#define TEST_WORDS 16

void main(void)
{
    // First write deterministic 32-bit values to the additional Wishbone RAM.
    for (int i = 0; i < TEST_WORDS; i++) {
        int value = 0x13579BDF ^ (i * 0x01010101);
        write_int(IP_RAM_ADDR + 4 * i, value);
    }

    // Then read them back through the processor and compare.
    for (int i = 0; i < TEST_WORDS; i++) {
        int expected = 0x13579BDF ^ (i * 0x01010101);
        int actual = read_int(IP_RAM_ADDR + 4 * i);

        if (actual != expected) {
            write_int(GPIO_ADDR, 0);       // LED0 = 0 -> FAIL
            write_int(GPIO_ADDR + 4, i + 1); // failing word number
            return;
        }
    }

    write_int(GPIO_ADDR + 4, 0);
    write_int(GPIO_ADDR, 1);               // LED0 = 1 -> PASS
}
