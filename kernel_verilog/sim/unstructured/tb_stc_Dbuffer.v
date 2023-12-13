`timescale 1ns/1ps

module tb_stc_Dbuffer();

parameter N = 16;
parameter M = 16;
parameter N_PE = 4;
parameter DW_MEM = 256;
parameter DW_DATA = 16;
parameter DW_COL = 4;

reg clk;
reg reset;
reg write_outside_en;
reg [DW_COL-1:0] col;
reg [DW_MEM-1:0] C_input;
reg [N_PE-1:0] write_inside_en;
reg [N_PE*DW_COL-1:0] cols_in;
reg [N_PE*N*DW_DATA-1:0] D_rows;
reg [N_PE*DW_COL-1:0] cols_out;
wire [N_PE*N*DW_DATA-1:0] C_rows;
wire [N*DW_DATA-1:0] D_row_out;

always #5 clk = ~clk;
reg [15:0] memory [0:255];
integer i, j;

initial begin
    $readmemb("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Bbuf.txt", memory);
	clk = 1;
    reset = 1;
    write_outside_en = 0;
    col = 0;
    C_input = 0;
    write_inside_en = 0;
    cols_in = 0;
    D_rows = 0;
    cols_out = 0;
    #10
    reset = 0;
    write_outside_en = 1;
    for (i=0; i<M; i=i+1) begin
        col = i;
        for (j=0; j<N; j=j+1) begin
            C_input[j*DW_DATA +:DW_DATA] = memory[i*M+j];
        end
        #10;
    end
    write_outside_en = 0;
    write_inside_en = 1;
    cols_in = {4'd3, 4'd2, 4'd1, 4'd0};
    for (i=0; i<N_PE; i=i+1) begin
        for (j=0; j<N; j=j+1) begin
            D_rows[(i*M+j)*DW_DATA +:DW_DATA] = memory[(i+1)*M+j];
        end
    end
    #10
    write_inside_en = 0;
    cols_out = {4'd3, 4'd2, 4'd1, 4'd0};
    for (i=0; i<M; i=i+1) begin
        col = i;
        #10;
    end
    
    $finish;
end


stc_Dbuffer#(
    .DW_DATA(DW_DATA),
    .DW_MEM(DW_MEM)
) u_Dbuffer (
    .clk(clk),
    .reset(reset),
    .write_outside_en(write_outside_en),
    .col(col),
    .C_input(C_input),
    .write_inside_en(write_inside_en),
    .cols_in(cols_in),
    .D_rows(D_rows),
    .cols_out(cols_out),
    .C_rows(C_rows),
    .D_row_out(D_row_out)
);

endmodule