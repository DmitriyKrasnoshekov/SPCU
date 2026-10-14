#!/bin/bash
set -e

FW_SOURCE="${1:-firmware_quicksort.c}"
shift || true

if [ -x "$HOME/riscv-gnu-toolchain/installed-tools/bin/riscv32-unknown-elf-gcc" ]; then
    PREFIX="$HOME/riscv-gnu-toolchain/installed-tools/bin/riscv32-unknown-elf-"
else
    PREFIX="riscv32-unknown-elf-"
fi

GCC="${PREFIX}gcc"
OBJCOPY="${PREFIX}objcopy"

if ! command -v "$GCC" >/dev/null 2>&1 && [ ! -x "$GCC" ]; then
    echo "RISC-V GCC not found: $GCC"
    echo "Install the toolchain from the laboratory manual or add it to PATH."
    exit 1
fi

if [ ! -f "./firmware/$FW_SOURCE" ]; then
    echo "Firmware source not found: ./firmware/$FW_SOURCE"
    exit 1
fi

"$GCC" -Os -ffreestanding -fno-builtin -nostdlib \
    -o ./firmware/firmware.elf \
    ./firmware/firmware.S ./firmware/"$FW_SOURCE" \
    --std=gnu99 "$@" \
    -Wl,-Bstatic,-T,./firmware/firmware.lds,-Map,firmware.map,--strip-debug \
    -lgcc

"$OBJCOPY" -O binary ./firmware/firmware.elf ./firmware/firmware.bin

BIN_SIZE=$(wc -c < ./firmware/firmware.bin)
if [ "$BIN_SIZE" -gt 16384 ]; then
    echo "ERROR: firmware.bin is $BIN_SIZE bytes, but firmware.mem contains only 16 KiB."
    exit 1
fi

python3 ./firmware/makehex.py ./firmware/firmware.bin 4096 > ./firmware/firmware.hex
mv ./firmware/firmware.hex firmware.mem

echo "Built $FW_SOURCE -> firmware.mem ($BIN_SIZE bytes of program image)"
