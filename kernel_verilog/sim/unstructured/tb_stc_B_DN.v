`timescale 1ns/1ps

module tb_stc_B_DN();

parameter N = 16;
parameter K = 16;
parameter DW_DATA = 16;
parameter DW_COL = 4;
parameter N_PE = 4;

reg clk;
reg reset;
reg [K*N*DW_DATA-1:0] in_b;
reg [N_PE*DW_COL-1:0] in_cols;
wire [N_PE*N*DW_DATA-1:0] out_b;

always #5 clk = ~clk;
reg [15:0] memory [0:255];
integer i, j;

initial begin
    $readmemb("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Bbuf.txt", memory);
	clk = 1;
    reset = 1;
    in_b = 0;
    in_cols = 0;
    #10
    reset = 0;
    for (i=0; i<256; i=i+1) begin
        in_b[i*DW_DATA +:DW_DATA] = memory[i];
    end
    in_cols = {4'd3, 4'd2, 4'd1, 4'd0};
    #10
    in_cols = {4'd7, 4'd6, 4'd5, 4'd4};
    #100
    
    $finish;
end

stc_B_DN #(
    .DW_DATA(DW_DATA)
) u_B_DN (
    .clk(clk),
    .reset(reset),
    .in_b(in_b),
    .in_cols(in_cols),
    .out_b(out_b)
);

endmodule