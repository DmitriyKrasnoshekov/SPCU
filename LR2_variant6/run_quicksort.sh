#!/bin/bash
set -e
./prog_make.sh firmware_quicksort.c
[ -x ./obj_dir/VPico_SoC ] || ./verilator_build.sh
./obj_dir/VPico_SoC quicksort
