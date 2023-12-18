`timescale 1ns/1ps

module tb_tc_Dbuffer();

parameter M = 16;
parameter N = 16;
parameter TILE_SIZE = 16;
parameter NUM_TILE = 16;
parameter TILE_N = 4;
parameter TILE_M = 4;
parameter ITER_N = 4;
parameter ITER_M = 4;
parameter DW_MEM = 256;
parameter DW_COL = 4;
parameter DW_DATA = 16;

reg clk;
reg reset;
// inside reg
reg write_inside_en;
reg [DW_COL-1:0] ptr_in;
reg [TILE_SIZE*DW_DATA-1:0] D_tile;
// inside wire
reg [DW_COL-1:0] ptr_out;
wire [TILE_SIZE*DW_DATA-1:0] C_tile;
// outside reg 
reg write_outside_en;
reg [DW_COL-1:0] row_in;
reg [DW_MEM-1:0] C_input;
// outside wire
reg [DW_COL-1:0] row_out;
wire [N*DW_DATA-1:0] D_row_out;

always #5 clk = ~clk;
reg [15:0] memory [0:255];
integer i, j;

initial begin
    $readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/basic/Cbuf.txt", memory);
	clk = 1;
    reset = 1;
    write_outside_en = 0;
    row_in = 0;
    C_input = 0;
    write_inside_en = 0;
    ptr_in = 0;
    D_tile = 0;
    ptr_out = 0;
    #10
    reset = 0;
    write_outside_en = 1;
    for (i=0; i<M; i=i+1) begin
        row_in = i;
        for (j=0; j<N; j=j+1) begin
            C_input[j*DW_DATA +:DW_DATA] = memory[i*M+j];
        end
        #10;
    end
    write_outside_en = 0;
    write_inside_en = 1;
    ptr_in = 4'd0;
    for (j=0; j<N; j=j+1) begin
        D_tile[j*DW_DATA +:DW_DATA] = memory[j];
    end
    #10
    write_inside_en = 0;
    ptr_out = 4'd1;
    for (i=0; i<M; i=i+1) begin
        row_out = i;
        #10;
    end
    
    $finish;
end


tc_Dbuffer#(
    .DW_DATA(DW_DATA),
    .DW_MEM(DW_MEM)
) u_Dbuffer (
    .clk(clk),
    .reset(reset),
    .write_inside_en(write_inside_en),
    .ptr_in(ptr_in),
    .D_tile(D_tile),
    .ptr_out(ptr_out),
    .C_tile(C_tile),
    .write_outside_en(write_outside_en),
    .row_in(row_in),
    .C_input(C_input),
    .row_out(row_out),
    .D_row_out(D_row_out)
);

endmodule