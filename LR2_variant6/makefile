FW ?= firmware_quicksort.c

.PHONY: firmware verilator quicksort ram array-limit clean

firmware:
	./prog_make.sh $(FW)

verilator:
	./verilator_build.sh

quicksort:
	./run_quicksort.sh

ram:
	./run_wb_ram_test.sh

array-limit:
	./find_max_array.sh

clean:
	rm -rf obj_dir firmware.mem firmware.map verilator.vcd qqq system.vcd
	rm -f firmware/firmware.elf firmware/firmware.bin firmware/firmware.hex
