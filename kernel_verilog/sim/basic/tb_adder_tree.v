`timescale 1ns / 1ps

module tb_adder_tree();
parameter DW_DATA = 8;
//
parameter NUM_IN = 8;

reg clk;
reg rst;
reg [NUM_IN*DW_DATA-1:0] in;
wire [DW_DATA-1:0] out;

initial begin
    clk = 1'b1;
end
always #5 clk = ~clk;

initial begin
    in = 0;
    rst = 1'b1;
    #10
    rst = 1'b0;
    in = {64'h07_06_05_04_03_02_01_00};
    #10 
    in = {64'h00_01_02_03_04_05_06_06};
    #10
    in = {64'h07_06_05_04_03_02_01_00};
    #100 $finish;
end

adder_tree #(
    .DW_DATA(DW_DATA),
    .NUM_IN(NUM_IN)
) u_adder_tree (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

endmodule   