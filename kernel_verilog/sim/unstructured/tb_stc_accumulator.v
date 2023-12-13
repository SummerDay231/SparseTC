`timescale 1ns/1ps

module tb_stc_accumulator();

parameter N = 16;
parameter N_PE = 4;
parameter DW_DATA = 16;

reg clk;
reg reset;
reg [N_PE*N*DW_DATA-1:0] in_mult;
reg [N_PE*N*DW_DATA-1:0] in_psum;
reg [N_PE-1:0] acc_en;
wire [N_PE*N*DW_DATA-1:0] out;

always #5 clk = ~clk;
reg [15:0] memory [0:255];
integer i, j;

initial begin
    $readmemb("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Abuf.txt", memory);
	clk = 1;
    reset = 1;
    in_mult = 0;
    in_psum = 0;
    acc_en = 0;
    #10
    reset = 0;
    acc_en = 4'b1111;
    for (i=0; i<N_PE; i=i+1) begin
        for (j=0; j<N; j=j+1) begin
            in_psum[(i*N+j)*DW_DATA +:DW_DATA] = memory[i*N+j];
        end
    end
    for (i=0; i<N_PE; i=i+1) begin
        for (j=0; j<N; j=j+1) begin
            in_mult[(i*N+j)*DW_DATA +:DW_DATA] = memory[i*N+j];
        end
    end
    #10
    acc_en = 0;
    for (i=0; i<N_PE; i=i+1) begin
        for (j=0; j<N; j=j+1) begin
            in_mult[(i*N+j)*DW_DATA +:DW_DATA] = memory[(i+1)*N+j];
        end
    end
    #10
    for (i=0; i<N_PE; i=i+1) begin
        for (j=0; j<N; j=j+1) begin
            in_mult[(i*N+j)*DW_DATA +:DW_DATA] = memory[(i+2)*N+j];
        end
    end
    #100
    $finish;
end

stc_accumulator#(
    .DW_DATA(DW_DATA)
) u_stc_accumulator (
    .clk(clk),
    .reset(reset),
    .in_mult(in_mult),
    .in_psum(in_psum),
    .acc_en(acc_en),
    .out(out)
);

endmodule