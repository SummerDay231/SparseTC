`timescale 1ns / 1ps

module stc_A_DN #(
    parameter N = 16,
    parameter DW_DATA = 16,
    parameter N_PE = 4
) (
    input clk,
    input reset,
    input [N_PE*DW_DATA-1:0] in_a,
    output [N_PE*N*DW_DATA-1:0] out_a
);

    reg [N_PE*DW_DATA-1:0] reg_in_a;
    always @(posedge clk) begin
        if (reset) reg_in_a <= 0;
        else reg_in_a <= in_a;
    end

    genvar gi;
    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign out_a[gi*N*DW_DATA +:N*DW_DATA] = {N{reg_in_a[gi*DW_DATA +:DW_DATA]}};
        end
    endgenerate

endmodule