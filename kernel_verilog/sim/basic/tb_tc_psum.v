`timescale 1ns / 1ps

module tb_tc_psum();
parameter M = 16;
parameter N = 16;
parameter tileM = 4;
parameter tileK = 8;
parameter tileN = 1;
parameter NUM_IN = 32;
parameter DW_DATA = 8;
parameter DW_POS = 4;
parameter NUM_OUT = N;
parameter DW_OUT = NUM_OUT*DW_DATA;

reg clk;
reg rst;
reg [DW_POS-1:0] col;
reg [DW_POS-1:0] row;
reg [tileM*DW_DATA-1:0] in;
reg out_en;
wire out_valid;
wire [DW_OUT-1:0] out;

always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    rst = 1'b1;
    col = 0;
    row = 0;
    out_en = 0;
    in = {8'h02, 8'h03, 8'h01, 8'h00};
    #10
    rst = 1'b0;
    #60
    out_en = 1;
    #160
    $finish;
end

tc_psum #(
    .DW_DATA(DW_DATA)
) u_tc_psum (
    .clk(clk),
    .rst(rst),
    .col(col),
    .row(row),
    .in(in),
    .out_en(out_en),
    .out_valid(out_valid),
    .out(out)
);

endmodule