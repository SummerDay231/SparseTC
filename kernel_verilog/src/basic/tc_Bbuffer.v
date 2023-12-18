`timescale 1ns / 1ps

module tc_Bbuffer #(
    parameter N = 16,
    parameter K = 16,
    parameter TILE_N = 4,
    parameter TILE_K = 4,
    parameter iterN = N / TILE_N,
    parameter iterK = K / TILE_K,
    parameter N_iter = iterN * iterK,
    parameter DW_MEM = 512,
    parameter DW_IDX = 4,
    parameter DW_DATA = 32,
    parameter DW_TILE = TILE_N*TILE_K*DW_DATA
) (
    input clk,
    input reset,
    input write_en,
    input [DW_MEM-1:0] B_input,
    input [DW_IDX-1:0] row_in,
    input [DW_IDX-1:0] ptr_out,
    output [DW_TILE-1:0] B_tile
);

    reg [DW_TILE-1:0] reg_B [N_iter-1:0];
    wire [4*DW_DATA-1:0] wire_row_in [3:0];

    integer i;
    genvar gi;
    generate
        for (gi=0; gi<TILE_K; gi=gi+1) begin
            assign wire_row_in[gi] = B_input[gi*TILE_N*DW_DATA +:TILE_N*DW_DATA];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<N_iter; i=i+1) begin
                reg_B[i] <= 0;
            end
        end
        else begin
            if (write_en) begin
                //reg_A[ptr_in] <= A_input;
                for (i=0; i<iterK; i=i+1) begin
                    reg_B[row_in[3:2]*iterN+i][row_in[1:0]*TILE_N*DW_DATA +:TILE_N*DW_DATA] <= wire_row_in[i];
                end
            end         
        end
    end

    assign B_tile = reg_B[ptr_out];

endmodule

