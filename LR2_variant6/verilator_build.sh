#!/bin/bash
set -e

verilator \
    --cc \
    --exe \
    --build \
    --trace \
    -Wno-fatal \
    --top-module Pico_SoC \
    Pico_SoC.v \
    picorv32.v \
    wb_ram.v \
    wb_ram_ip.v \
    wb_gpio.v \
    wbxbar.v \
    addrdecode.v \
    skidbuffer.v \
    tb_verilator.cpp

echo "Built: ./obj_dir/VPico_SoC"
