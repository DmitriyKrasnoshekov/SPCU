#!/bin/bash
set -e

# The exact limit depends on compiler-generated code and stack usage.
# Search it on the same RISC-V toolchain that is used for the laboratory.
[ -x ./obj_dir/VPico_SoC ] || ./verilator_build.sh

low=1
high=5000
best=0

while [ "$low" -le "$high" ]; do
    mid=$(( (low + high) / 2 ))
    echo "Testing ARRAY_SIZE=$mid ..."

    ./prog_make.sh firmware_array_limit.c -DARRAY_SIZE=$mid >/dev/null

    set +e
    ./obj_dir/VPico_SoC array "$mid" --no-trace >/dev/null 2>&1
    result=$?
    set -e

    if [ "$result" -eq 0 ]; then
        best=$mid
        low=$((mid + 1))
    else
        high=$((mid - 1))
    fi
done

echo "Maximum working local int array for this test/toolchain: $best elements"
echo "For the report, also mention that the startup code initializes SP to 16368 (0x3FF0)."
