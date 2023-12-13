`timescale 1ns / 1ps

module tb_tc_array();
parameter N_UNIT = 32;
parameter TILE_M = 4;
parameter TILE_K = 8;
parameter DW_DATA = 8;

reg clk;
reg reset;
// input 
reg [N_UNIT*DW_DATA-1:0] in_a;
reg [N_UNIT*DW_DATA-1:0] in_b;
// output
wire [TILE_M*DW_DATA-1:0] out;

always #5 clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    in_a = {8'd2, 8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 
            8'd7, 8'd1, 8'd5, 8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 
            8'd6, 8'd7, 8'd7, 8'd5, 8'd0, 8'd1, 8'd2, 8'd3, 
            8'd5, 8'd6, 8'd0, 8'd1, 8'd3, 8'd4, 8'd6, 8'd7};
    in_b = {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0,
            8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0,
            8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0,
            8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
    #10
    reset = 0;
    #10
    in_a = 0;
    #10
    in_a = {8'd2, 8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 
            8'd7, 8'd1, 8'd5, 8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 
            8'd6, 8'd7, 8'd7, 8'd5, 8'd0, 8'd1, 8'd2, 8'd3, 
            8'd5, 8'd6, 8'd0, 8'd1, 8'd3, 8'd4, 8'd6, 8'd7};
    #100 $finish;
end

tc_array u_tc_array (
    .clk(clk),
    .reset(reset),
    .in_a(in_a),
    .in_b(in_b),
    .out(out)
);

endmodule