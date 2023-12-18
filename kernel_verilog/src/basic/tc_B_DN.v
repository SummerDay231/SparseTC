`timescale 1ns / 1ps

module tc_B_DN #(
    parameter NUM_TILE = 16,
    parameter STEP = 4,
    parameter DW_DATA = 16,
    parameter N_PE = 4
) (
    input clk,
    input reset,
    input [NUM_TILE*DW_DATA-1:0] in_b,
    output [N_PE*NUM_TILE*DW_DATA-1:0] out_b
);

    integer i, j;

    reg [NUM_TILE*DW_DATA-1:0] reg_in_b;
    always @(posedge clk) begin
        if (reset) reg_in_b <= 0;
        else begin
            for (i=0; i<4; i=i+1) begin
                for (j=0; j<4; j=j+1) begin
                    reg_in_b[(i*4+j)*DW_DATA +:DW_DATA] <= in_b[(j*4+i)*DW_DATA +:DW_DATA];
                end
            end
        end
    end

    genvar gi;
    generate
        for (gi=0; gi<4; gi=gi+1) begin
            assign out_b[gi*16*DW_DATA +:16*DW_DATA] = reg_in_b;
        end
    endgenerate

endmodule