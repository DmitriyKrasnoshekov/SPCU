`timescale 1 ns / 1 ps

module Pico_SoC (
    input  wire        clk,
    input  wire        f_clk,
    input  wire        rst,
    output wire [31:0] gpio,
    output wire [31:0] gpio1,
    output wire        trap
);

    // f_clk оставлен для совместимости с исходным проектом.
    // В этой лабораторной он не используется.
    wire unused_f_clk = f_clk;

    reg [31:0] irq = 0;

    wire        trace_valid;
    wire [35:0] trace_data;
    wire        mem_instr;

    // Master: PicoRV32
    wire [31:0] wb_adr_pico;
    wire [31:0] wb_dat_o_pico;
    wire [31:0] wb_dat_i_pico;
    wire [3:0]  wb_sel_pico;
    wire        wb_we_pico;
    wire        wb_cyc_pico;
    wire        wb_stb_pico;
    wire        wb_ack_pico;

    // Slave 0: program/data RAM from the original project
    wire [31:0] wb_adr_ram;
    wire [31:0] wb_dat_i_ram;
    wire [31:0] wb_dat_o_ram;
    wire [3:0]  wb_sel_ram;
    wire        wb_we_ram;
    wire        wb_cyc_ram;
    wire        wb_stb_ram;
    wire        wb_ack_ram;

    // Slave 1: GPIO
    wire [31:0] wb_adr_gpio;
    wire [31:0] wb_dat_i_gpio;
    wire [31:0] wb_dat_o_gpio;
    wire [3:0]  wb_sel_gpio;
    wire        wb_we_gpio;
    wire        wb_cyc_gpio;
    wire        wb_stb_gpio;
    wire        wb_ack_gpio;

    // Slave 2: second Wishbone RAM, task 2
    wire [31:0] wb_adr_ipram;
    wire [31:0] wb_dat_i_ipram;
    wire [31:0] wb_dat_o_ipram;
    wire [3:0]  wb_sel_ipram;
    wire        wb_we_ipram;
    wire        wb_cyc_ipram;
    wire        wb_stb_ipram;
    wire        wb_ack_ipram;

    // This RAM is mandatory: the RISC-V program is stored here.
    wb_ram #(
        .depth(2*4096),
        .memfile("firmware.mem")
    ) boot_ram (
        .wb_clk_i(clk),
        .wb_rst_i(rst),
        .wb_adr_i(wb_adr_ram),
        .wb_dat_i(wb_dat_i_ram),
        .wb_stb_i(wb_stb_ram),
        .wb_cyc_i(wb_cyc_ram),
        .wb_dat_o(wb_dat_o_ram),
        .wb_ack_o(wb_ack_ram),
        .wb_sel_i(wb_sel_ram),
        .wb_we_i(wb_we_ram),
        .mem_instr(mem_instr),
        .tests_passed()
    );

    wb_gpio #(
        .GPIO_ADDR(32'h1001_0000)
    ) gpio_unit (
        .clk_i(clk),
        .rst_i(rst),
        .cyc_i(wb_cyc_gpio),
        .stb_i(wb_stb_gpio),
        .adr_i(wb_adr_gpio),
        .we_i(wb_we_gpio),
        .data_i(wb_dat_i_gpio),
        .data_o(wb_dat_o_gpio),
        .ack_o(wb_ack_gpio),
        .gpio(gpio),
        .gpio1(gpio1)
    );

    // Additional 4 KiB Wishbone RAM from task 2.
    // The interface follows the wb_ram core used in the assignment repository.
    wb_ram_ip #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(12)
    ) ip_ram (
        .clk(clk),
        .adr_i(wb_adr_ipram[11:0]),
        .dat_i(wb_dat_i_ipram),
        .dat_o(wb_dat_o_ipram),
        .we_i(wb_we_ipram),
        .sel_i(wb_sel_ipram),
        .stb_i(wb_stb_ipram),
        .ack_o(wb_ack_ipram),
        .cyc_i(wb_cyc_ipram)
    );

    picorv32_wb #(
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .ENABLE_IRQ(1),
        .ENABLE_TRACE(1)
    ) cpu (
        .trap(trap),
        .irq(irq),
        .trace_valid(trace_valid),
        .trace_data(trace_data),
        .mem_instr(mem_instr),

        .wb_clk_i(clk),
        .wb_rst_i(rst),

        .wbm_adr_o(wb_adr_pico),
        .wbm_dat_i(wb_dat_i_pico),
        .wbm_stb_o(wb_stb_pico),
        .wbm_ack_i(wb_ack_pico),
        .wbm_cyc_o(wb_cyc_pico),
        .wbm_dat_o(wb_dat_o_pico),
        .wbm_we_o(wb_we_pico),
        .wbm_sel_o(wb_sel_pico),

        // PCPI is unused in this laboratory.
        .pcpi_wr(1'b0),
        .pcpi_rd(32'b0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0)
    );

    // Address map:
    // 0x0000_0000 ... 0x0000_FFFF  - boot RAM
    // 0x1001_0000 ... 0x1001_0FFF  - GPIO
    // 0x1002_0000 ... 0x1002_0FFF  - task-2 Wishbone RAM
    wbxbar #(
        .NM(1),
        .NS(3),
        .AW(32),
        .DW(32),
        .SLAVE_ADDR({
            32'h0000_0000,
            32'h1001_0000,
            32'h1002_0000
        }),
        .SLAVE_MASK({
            32'hFFFF_0000,
            32'hFFFF_F000,
            32'hFFFF_F000
        })
    ) crossbar (
        .i_clk(clk),
        .i_reset(rst),

        .i_mcyc(wb_cyc_pico),
        .i_mstb(wb_stb_pico),
        .i_mwe(wb_we_pico),
        .i_maddr(wb_adr_pico),
        .i_mdata(wb_dat_o_pico),
        .i_msel(wb_sel_pico),
        .o_mstall(),
        .o_mack(wb_ack_pico),
        .o_mdata(wb_dat_i_pico),
        .o_merr(),

        .o_scyc({wb_cyc_ram, wb_cyc_gpio, wb_cyc_ipram}),
        .o_sstb({wb_stb_ram, wb_stb_gpio, wb_stb_ipram}),
        .o_swe({wb_we_ram, wb_we_gpio, wb_we_ipram}),
        .o_saddr({wb_adr_ram, wb_adr_gpio, wb_adr_ipram}),
        .o_sdata({wb_dat_i_ram, wb_dat_i_gpio, wb_dat_i_ipram}),
        .o_ssel({wb_sel_ram, wb_sel_gpio, wb_sel_ipram}),
        .i_sstall(3'b000),
        .i_sack({wb_ack_ram, wb_ack_gpio, wb_ack_ipram}),
        .i_sdata({wb_dat_o_ram, wb_dat_o_gpio, wb_dat_o_ipram}),
        .i_serr(3'b000)
    );

endmodule
