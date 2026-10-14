#!/bin/bash
set -e
./prog_make.sh firmware_wb_ram_test.c
[ -x ./obj_dir/VPico_SoC ] || ./verilator_build.sh
./obj_dir/VPico_SoC ram
