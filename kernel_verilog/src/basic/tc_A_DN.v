`timescale 1ns / 1ps

module tc_A_DN #(
    parameter NUM_TILE = 16,
    parameter STEP = 4,
    parameter DW_DATA = 16,
    parameter N_PE = 4
) (
    input clk,
    input reset,
    input [NUM_TILE*DW_DATA-1:0] in_a,
    output [N_PE*NUM_TILE*DW_DATA-1:0] out_a
);

    reg [NUM_TILE*DW_DATA-1:0] reg_in_a;
    always @(posedge clk) begin
        if (reset) reg_in_a <= 0;
        else reg_in_a <= in_a;
    end

    genvar gi;
    generate
        for (gi=0; gi<4; gi=gi+1) begin
            assign out_a[gi*16*DW_DATA +:16*DW_DATA] = {4{reg_in_a[gi*4*DW_DATA +:4*DW_DATA]}};
        end
    endgenerate

endmodule