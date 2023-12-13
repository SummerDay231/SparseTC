`timescale 1ns / 1ps

module tb_stc_cu();
parameter M = 16;
parameter DW_MEM = 512;
parameter DW_ROWIDX = 4;
parameter DW_ELEIDX = 8;
parameter N_PE = 4;
parameter DW_DATA = 8;
parameter DW_ROWPTR = (M+1)*DW_ELEIDX;
parameter DW_ROW2ROW = M*DW_ROWIDX;
parameter DW_WKLDPTR = N_PE*DW_ROWIDX;

reg clk;
reg reset;
reg write_en;
reg [DW_MEM-1:0] cu_input;
wire [N_PE*DW_ELEIDX-1:0] A_ptr;
wire [N_PE-1:0] acc_en;
wire [N_PE-1:0] write_D_en;
wire [N_PE*DW_ROWIDX-1:0] A_row;
wire out_valid;
wire [DW_ROWIDX-1:0] D_row;

always #5 clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    write_en = 0;
    cu_input = 0;
    #10
    reset = 0;
    write_en = 1;
    cu_input = {4'd0, 4'd12, 4'd8, 4'd5, 4'd0,
                4'd15, 4'd14, 4'd13, 4'd12, 4'd11, 4'd10, 4'd9, 4'd8,
                4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0,
                8'd64, 8'd61, 8'd58, 8'd54, 8'd49, 8'd48, 8'd44, 8'd39, 8'd33,
                8'd31, 8'd25, 8'd17, 8'd16, 8'd16, 8'd13, 8'd9, 8'd0};
    #10
    write_en = 0;
    #400
    $finish;
end

stc_cu #(
    .M(M)
) u_cu (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .cu_input(cu_input),
    .A_ptrs(A_ptrs),
    .acc_en(acc_en),
    .write_D_en(write_D_en),
    .A_rows(A_rows),
    .out_valid(out_valid),
    .row_out(D_row)
);

endmodule