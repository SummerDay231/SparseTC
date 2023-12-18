`timescale 1ns/1ps

module tb_tc_A_DN();

parameter NUM_TILE = 16;
parameter STEP = 4;
parameter DW_DATA = 16;
parameter N_PE = 4;

reg clk;
reg reset;
reg [NUM_TILE*DW_DATA-1:0] in_a;
wire [N_PE*NUM_TILE*DW_DATA-1:0] out_a;

always #5 clk = ~clk;
//reg [15:0] memory [0:255];

initial begin
    //$readmemb("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Bbuf.txt", memory);
	clk = 1;
    reset = 1;
    in_a = 0;
    #10
    reset = 0;
    in_a = {16'd15, 16'd14, 16'd13, 16'd12, 16'd11, 16'd10, 16'd9, 16'd8,
            16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0};
    #100
    $finish;
end


tc_A_DN#(
    .DW_DATA(DW_DATA)
) u_A_DN (
    .clk(clk),
    .reset(reset),
    .in_a(in_a),
    .out_a(out_a)
);

endmodule