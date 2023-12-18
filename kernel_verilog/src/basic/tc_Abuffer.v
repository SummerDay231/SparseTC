`timescale 1ns / 1ps

module tc_Abuffer #(
    parameter M = 16,
    parameter K = 16,
    parameter TILE_M = 4,
    parameter TILE_K = 4,
    parameter iterM = M / TILE_M,
    parameter iterK = K / TILE_K,
    parameter N_iter = iterM * iterK,
    parameter DW_MEM = 512,
    parameter DW_IDX = 4,
    parameter DW_DATA = 32,
    parameter DW_TILE = TILE_M*TILE_K*DW_DATA
) (
    input clk,
    input reset,
    input write_en,
    input [DW_MEM-1:0] A_input,
    input [DW_IDX-1:0] row_in,
    input [DW_IDX-1:0] ptr_out,
    output [DW_TILE-1:0] A_tile
);

    reg [DW_TILE-1:0] reg_A [N_iter-1:0];
    wire [4*DW_DATA-1:0] wire_row_in [3:0];

    integer i;
    genvar gi;
    generate
        for (gi=0; gi<TILE_M; gi=gi+1) begin
            assign wire_row_in[gi] = A_input[gi*TILE_K*DW_DATA +:TILE_K*DW_DATA];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<N_iter; i=i+1) begin
                reg_A[i] <= 0;
            end
        end
        else begin
            if (write_en) begin
                //reg_A[ptr_in] <= A_input;
                for (i=0; i<iterM; i=i+1) begin
                    reg_A[row_in[3:2]*iterK+i][row_in[1:0]*TILE_K*DW_DATA +:TILE_K*DW_DATA] <= wire_row_in[i];
                end
            end         
        end
    end

    assign A_tile = reg_A[ptr_out];

endmodule

