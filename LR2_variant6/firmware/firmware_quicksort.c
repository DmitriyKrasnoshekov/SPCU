#include "firmware_common.h"

#define N 20

// Global writable array: its initial values are loaded directly with firmware.mem.
// This avoids depending on libc/memcpy in the freestanding firmware.
static int data[N] = {
    17, -4, 23, 0, 8,
    -11, 42, 5, 19, 3,
    -2, 31, 14, 1, 27,
    9, 6, 35, 12, 21
};

static void swap(int *a, int *b)
{
    int t = *a;
    *a = *b;
    *b = t;
}

static int partition(int a[], int left, int right)
{
    int pivot = a[right];
    int i = left - 1;

    for (int j = left; j < right; j++) {
        if (a[j] <= pivot) {
            i++;
            swap(&a[i], &a[j]);
        }
    }

    swap(&a[i + 1], &a[right]);
    return i + 1;
}

static void quicksort(int a[], int left, int right)
{
    if (left < right) {
        int p = partition(a, left, right);
        quicksort(a, left, p - 1);
        quicksort(a, p + 1, right);
    }
}

void main(void)
{
    quicksort(data, 0, N - 1);

    // GPIO contains the sorted value.
    // GPIO+4 contains its 1-based index, which lets the Verilator testbench
    // detect every output even if two neighbouring values were equal.
    for (int i = 0; i < N; i++) {
        write_int(GPIO_ADDR, data[i]);
        write_int(GPIO_ADDR + 4, i + 1);
    }
}
