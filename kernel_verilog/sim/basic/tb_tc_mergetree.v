`timescale 1ns / 1ps

module tb_tc_mergetree();
parameter N_UNIT = 64;
parameter N_MERGE = 16;
parameter TILE_K = 4;
parameter DW_DATA = 16;

reg clk;
reg reset;
reg [N_UNIT*DW_DATA-1:0] in_mult;
reg [N_MERGE*DW_DATA-1:0] in_psum;
wire [N_MERGE*DW_DATA-1:0] out;

always #5 clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    in_mult = 0;
    in_psum = 0;
    #10
    reset = 0;
    in_mult = {16'd15, 16'd14, 16'd13, 16'd12, 16'd11, 16'd10, 16'd9, 16'd8,
            16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0,
            16'd15, 16'd14, 16'd13, 16'd12, 16'd11, 16'd10, 16'd9, 16'd8,
            16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0,
            16'd15, 16'd14, 16'd13, 16'd12, 16'd11, 16'd10, 16'd9, 16'd8,
            16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0,
            16'd15, 16'd14, 16'd13, 16'd12, 16'd11, 16'd10, 16'd9, 16'd8,
            16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0};
    in_psum = {64{16'd1}};
    #10
    in_mult = 0;
    in_psum = 0;
    #100
    $finish;
end

tc_mergetree #(
    .DW_DATA(DW_DATA)
) u_mt (
    .clk(clk),
    .reset(reset),
    .in_mult(in_mult),
    .in_psum(in_psum),
    .out(out)
);

endmodule