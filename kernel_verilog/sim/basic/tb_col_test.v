`timescale 1ns / 1ps

module tb_col_test();
parameter M = 4;
parameter DW_POS = 4;
parameter DW_DATA = 8;

reg clk;
reg rst;
reg [DW_POS-1:0] col;
reg [M*DW_DATA-1:0] in;
wire [M*DW_DATA-1:0] out;

always #5 clk = ~clk;

initial begin
    clk = 1;
    rst = 1;
    # 10
    rst = 0;
    col = 0;
    in = {8'd3, 8'd2, 8'd1, 8'd4};
    # 20
    col = 1;
    # 20
    $finish;
end

col_test #(
    .M(M)
) col_test_u (
    .clk(clk),
    .rst(rst),
    .col(col),
    .in(in),
    .out(out)
);

endmodule