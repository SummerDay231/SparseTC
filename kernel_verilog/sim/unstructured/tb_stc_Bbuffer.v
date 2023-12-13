`timescale 1ns/1ps

module tb_stc_Bbuffer();

parameter N = 16;
parameter K = 16;
parameter DW_MEM = 256;
parameter DW_DATA = 16;
parameter DW_COL = 4;
parameter DW_PTR = 8;

reg clk;
reg reset;
reg write_data_en;
reg write_cidx_en;
reg [DW_MEM-1:0] A_data_input;
reg [DW_MEM-1:0] A_colidx_input;
reg [DW_COL-1:0] idx;
reg [DW_PTR*4-1:0] ptrs;
wire [DW_DATA*4-1:0] data;
wire [DW_COL*4-1:0] cols;

always #5 clk = ~clk;
reg [15:0] memory [0:255];
integer i, j;

initial begin
    $readmemb("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Abuf.txt", memory);
	clk = 1;
    reset = 1;
    write_cidx_en = 0;
    write_data_en = 0;
    A_data_input = 0;
    A_colidx_input = 0;
    idx = 0;
    ptrs = 0;
    #10
    reset = 0;
    write_data_en = 1;
    for (i=0; i<M; i=i+1) begin
        idx = i;
        for (j=0; j<K; j=j+1) begin
            A_data_input[j*DW_DATA +:DW_DATA] = memory[i*M+j];
        end
        #10;
    end
    for (i=0; i<10; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            ptrs[i*DW_PTR+j*DW_PTR +:DW_PTR] <= 4*i+j;
        end
        #10;
    end
    
    $finish;
end

// initial begin
//     clk = 1;
//     reset = 1;
//     #10
//     reset = 0;
//     ptrs = {10'd34, 10'd5, 10'd3, 10'd0};
//     #100 $finish;
// end

stc_Abuffer#(
    .DW_DATA(DW_DATA)
) u_Abuffer (
    .clk(clk),
    .reset(reset),
    .write_data_en(write_data_en),
    .write_cidx_en(write_cidx_en),
    .A_data_input(A_data_input),
    .A_colidx_input(A_colidx_input),
    .idx(idx),
    .ptrs(ptrs),
    .data(data),
    .cols(cols)
);

endmodule