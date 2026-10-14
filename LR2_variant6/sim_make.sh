#!/bin/bash
set -e

iverilog -g2009 -s system_tb -o qqq \
    tb.v Pico_SoC.v picorv32.v wb_ram.v wb_ram_ip.v wb_gpio.v \
    wbxbar.v addrdecode.v skidbuffer.v
vvp qqq
gtkwave system.vcd
