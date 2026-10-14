#ifndef FIRMWARE_COMMON_H
#define FIRMWARE_COMMON_H

#define GPIO_ADDR       0x10010000
#define IP_RAM_ADDR     0x10020000

static inline int read_int(int addr)
{
    return *(volatile int *)addr;
}

static inline void write_int(int addr, int value)
{
    *(volatile int *)addr = value;
}

#endif
