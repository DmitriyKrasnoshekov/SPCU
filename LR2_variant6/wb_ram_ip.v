`timescale 1 ns / 1 ps

// Additional Wishbone RAM for task 2.
// The port/parameter set is compatible with the wb_ram core referenced
// by the laboratory work.  The module name is changed to wb_ram_ip because
// the starter project already has a mandatory module named wb_ram.
module wb_ram_ip #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 12,
    parameter SELECT_WIDTH = DATA_WIDTH/8
)(
    input  wire                    clk,
    input  wire [ADDR_WIDTH-1:0]   adr_i,
    input  wire [DATA_WIDTH-1:0]   dat_i,
    output wire [DATA_WIDTH-1:0]   dat_o,
    input  wire                    we_i,
    input  wire [SELECT_WIDTH-1:0] sel_i,
    input  wire                    stb_i,
    output wire                    ack_o,
    input  wire                    cyc_i
);

    localparam BYTE_SHIFT = $clog2(SELECT_WIDTH);
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - BYTE_SHIFT;
    localparam WORD_SIZE = DATA_WIDTH / SELECT_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:(1<<WORD_ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] dat_o_reg = 0;
    reg                  ack_o_reg = 0;

    wire [WORD_ADDR_WIDTH-1:0] word_addr = adr_i[ADDR_WIDTH-1:BYTE_SHIFT];
    integer k;

    assign dat_o = dat_o_reg;
    assign ack_o = ack_o_reg;

    always @(posedge clk) begin
        ack_o_reg <= 1'b0;

        if (cyc_i && stb_i && !ack_o_reg) begin
            if (we_i) begin
                for (k = 0; k < SELECT_WIDTH; k = k + 1) begin
                    if (sel_i[k])
                        mem[word_addr][WORD_SIZE*k +: WORD_SIZE] <=
                            dat_i[WORD_SIZE*k +: WORD_SIZE];
                end
            end

            dat_o_reg <= mem[word_addr];
            ack_o_reg <= 1'b1;
        end
    end

endmodule
