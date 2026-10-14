#!/bin/bash
set -e

URL="https://raw.githubusercontent.com/alexforencich/verilog-wishbone/master/rtl/wb_ram.v"
TMP="wb_ram_ip.downloaded.v"

curl -L "$URL" -o "$TMP"

# The starter PicoSoC project already contains a different module called wb_ram.
# Rename only the module declaration so both RAMs can coexist.
sed 's/^module wb_ram #/module wb_ram_ip #/' "$TMP" > wb_ram_ip.v
rm "$TMP"

echo "Official alexforencich wb_ram downloaded and renamed to wb_ram_ip."
