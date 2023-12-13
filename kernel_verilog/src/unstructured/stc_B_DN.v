`timescale 1ns / 1ps

module stc_B_DN #(
    parameter K = 16,
    parameter N = 16,
    parameter N_PE = 4,
    parameter DW_DATA = 16,
    parameter DW_COL = 4
) (
    input clk,
    input reset,
    input [K*N*DW_DATA-1:0] in_b,
    input [N_PE*DW_COL-1:0] in_cols,
    output [N_PE*N*DW_DATA-1:0] out_b
);

    stc_crossbar #(
        .N_IN(K),
        .N_OUT(N_PE),
        .DW_DATA(DW_DATA),
        .DW_IDX(DW_COL),
        .NUM_PER_LINE(N)
    ) u_xbar (
        .clk(clk),
        .reset(reset),
        .in(in_b),
        .idx(in_cols),
        .out(out_b)
    );

endmodule