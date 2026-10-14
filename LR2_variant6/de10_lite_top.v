`timescale 1 ns / 1 ps

// Minimal board wrapper for DE10-Lite.
// Pin locations are intentionally not duplicated here: use the DE10-Lite
// pin assignments from the existing Quartus project / board template.
module de10_lite_top (
    input  wire        MAX10_CLK1_50,
    input  wire [1:0]  KEY,
    output wire [9:0]  LEDR
);

    wire [31:0] gpio;
    wire [31:0] gpio1;
    wire trap;

    // KEY[0] is active-low on the board; Pico_SoC expects active-high reset.
    wire rst = ~KEY[0];

    Pico_SoC soc (
        .clk(MAX10_CLK1_50),
        .f_clk(MAX10_CLK1_50),
        .rst(rst),
        .gpio(gpio),
        .gpio1(gpio1),
        .trap(trap)
    );

    // firmware_wb_ram_test.c:
    // LEDR[0] = 1 means PASS.
    // On FAIL LEDR[0] = 0 and LEDR[9:1] show the failing word number.
    assign LEDR[0]   = gpio[0];
    assign LEDR[9:1] = gpio1[8:0];

endmodule
