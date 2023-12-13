`timescale 1ns / 1ps

module tb_stc_crossbar();
parameter N_IN = 32;
parameter N_OUT = 4;
parameter DW_DATA = 8;
parameter DW_IDX = 5;
parameter NUM_PER_LINE = 1;

reg clk;
reg reset;
reg [N_OUT*DW_IDX-1:0] idx;
reg [N_IN*DW_DATA-1:0] in;
wire [N_OUT*DW_DATA-1:0] out;

always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    in = {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0,
          8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
    idx = {5'd1, 5'd4, 5'd5, 5'd14};
    // in = {8'd4, 8'd3, 8'd2, 8'd1};
    // ctrl = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
    #10
    reset = 1'b0;
    #20
    idx = {5'd11, 5'd14, 5'd15, 5'd24};
    #60
    $finish;
end

stc_crossbar #(
    .DW_DATA(DW_DATA),
    .N_IN(N_IN),
    .N_OUT(N_OUT),
    .NUM_PER_LINE(NUM_PER_LINE)
) u_stc_crossbar (
    .clk(clk),
    .reset(reset),
    .idx(idx),
    .in(in),
    .out(out)
);

endmodule