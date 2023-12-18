`timescale 1ns / 1ps

module tc_pe_array #(
    parameter N_PE = 4,
    parameter N = 16,
    parameter N_UNIT = N_PE*N,
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    input [N_UNIT*DW_DATA-1:0] in_a,
    input [N_UNIT*DW_DATA-1:0] in_b,
    output [N_UNIT*DW_DATA-1:0] out
);
    integer i;

    reg [DW_DATA-1:0] reg_out [N_UNIT-1:0];
    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<N_UNIT; i=i+1) begin
                reg_out[i] <= 0;
            end
        end
        else begin
            for (i=0; i<N_UNIT; i=i+1) begin
                reg_out[i] <= in_a[i*DW_DATA +:DW_DATA]*in_b[i*DW_DATA +:DW_DATA];
            end
        end
    end

    genvar gi;
    generate
        for (gi=0; gi<N_UNIT; gi=gi+1) begin
            assign out[gi*DW_DATA +:DW_DATA] = reg_out[gi];
        end
    endgenerate

endmodule