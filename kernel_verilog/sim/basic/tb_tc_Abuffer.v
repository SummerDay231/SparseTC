`timescale 1ns/1ps

module tb_tc_Abuffer();

parameter M = 16;
parameter K = 16;
parameter TILE_M = 4;
parameter TILE_K = 4;
parameter iterM = M / TILE_M;
parameter iterK = K / TILE_K;
parameter N_iter = iterM * iterK;
parameter DW_MEM = 256;
parameter DW_IDX = 4;
parameter DW_DATA = 16;
parameter DW_TILE = TILE_M*TILE_K*DW_DATA;

reg clk;
reg reset;
reg write_en;
reg [DW_MEM-1:0] A_input;
reg [DW_IDX-1:0] ptr_in;
reg [DW_IDX-1:0] ptr_out;
wire [DW_TILE-1:0] A_tile;

always #5 clk = ~clk;
reg [15:0] memory [0:255];
integer i, j;

initial begin
    $readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Bbuf0.txt", memory);
	clk = 1;
    reset = 1;
    write_en = 0;
    A_input = 0;
    ptr_in = 0;
    ptr_out = 0;
    #10
    reset = 0;
    write_en = 1;
    for (i=0; i<N_iter; i=i+1) begin
        ptr_in = i;
        for (j=0; j<TILE_M*TILE_K; j=j+1) begin
            A_input[j*DW_DATA +:DW_DATA] = memory[i*TILE_M*TILE_K+j];
        end
        #10;
    end
    for (i=0; i<10; i=i+1) begin
        ptr_out = i;
        #10;
    end
    
    $finish;
end

tc_Abuffer#(
    .DW_DATA(DW_DATA)
) u_Abuffer (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .A_input(A_input),
    .ptr_in(ptr_in),
    .ptr_out(ptr_out),
    .A_tile(A_tile)
);

endmodule