`timescale 1ns / 1ps

module tb_simple_cu();
parameter M = 7;
parameter DW_MEM = 512;
parameter DW_ROWIDX = 4;
parameter DW_ELEIDX = 8;
parameter N_PE = 1;
parameter DW_DATA = 8;
parameter DW_ROWPTR = (M+1)*DW_ELEIDX;
parameter DW_ROW2ROW = M*DW_ROWIDX;
parameter DW_WKLDPTR = N_PE*DW_ROWIDX;

reg clk;
reg reset;
reg write_en;
reg [DW_MEM-1:0] cu_input;
wire [DW_ELEIDX-1:0] A_ptr;
wire  acc_en;
wire [DW_ROWIDX-1:0] A_row;
wire out_valid;
wire [DW_ROWIDX-1:0] D_row;

always #5 clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    write_en = 0;
    cu_input = 0;
    #10
    reset = 0;
    write_en = 1;
    cu_input = {4'd7, 4'd0,
                4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0,
                8'd7, 8'd6, 8'd6, 8'd3, 8'd3, 8'd3, 8'd2, 8'd0};
    #10
    write_en = 0;
    #120
    $finish;
end

simple_cu #(
    .M(M)
) u_cu (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .cu_input(cu_input),
    .A_ptr(A_ptr),
    .acc_en(acc_en),
    .A_row(A_row),
    .out_valid(out_valid),
    .row(D_row)
);

endmodule