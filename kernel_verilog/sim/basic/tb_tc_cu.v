`timescale 1ns / 1ps

module tb_tc_cu();
parameter M = 16;
parameter N = 16;
parameter K = 16;
parameter tileN = 4;
parameter tileK = 4;
parameter iterN = 4;
parameter iterK = 4;
parameter N_UNIT = 32;
parameter DW_DATA = 8;
parameter DW_ROW = 4;
parameter DW_COL = 4;
parameter DW_CTRL = 4;

reg clk;
reg reset;
// input 
reg load_en;
reg compute_en;
wire [3:0] ptr_m;
wire [3:0] ptr_n;
wire [3:0] ptr_k;
wire out_valid;
wire [3:0] row_out;

always #5 clk = ~clk;



initial begin
    clk = 1;
    reset = 1;
    // $readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/in_a_dense.txt",in_a);
    // $readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/in_b.txt",in_b);
    load_en = 0;
    compute_en = 0;
    #10
    reset = 0;
    #10
    load_en = 1;
    #20
    load_en = 0;
    compute_en = 1;
    #10
    compute_en = 0;
    #2000 $finish;
end

tc_cu u_cu (
    .clk(clk),
    .reset(reset),
    .load_en(load_en),
    .compute_en(compute_en),
    .ptr_m(ptr_m),
    .ptr_n(ptr_n),
    .ptr_k(ptr_k),
    .out_valid(out_valid),
    .row_out(row_out)
);

endmodule