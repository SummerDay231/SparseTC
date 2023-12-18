`timescale 1ns / 1ps

module tc_Dbuffer #(
    parameter M = 16,
    parameter N = 16,
    parameter TILE_SIZE = 16,
    parameter NUM_TILE = 16,
    parameter TILE_N = 4,
    parameter TILE_M = 4,
    parameter ITER_N = 4,
    parameter ITER_M = 4,
    parameter DW_MEM = 512,
    parameter DW_COL = 4,
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    // inside input
    input write_inside_en,
    input [DW_COL-1:0] ptr_in,
    input [TILE_SIZE*DW_DATA-1:0] D_tile,
    // inside output
    input [DW_COL-1:0] ptr_out,
    output [TILE_SIZE*DW_DATA-1:0] C_tile,
    // outside input 
    input write_outside_en,
    input [DW_COL-1:0] row_in,
    input [DW_MEM-1:0] C_input,
    // outside output
    input [DW_COL-1:0] row_out,
    output [N*DW_DATA-1:0] D_row_out
);

    reg [TILE_SIZE*DW_DATA-1:0] reg_D_tile [NUM_TILE-1:0];
    wire [TILE_N*DW_DATA-1:0] wire_row_in [TILE_M-1:0];
    //wire [TILE_N*DW_DATA-1:0] wire_row_out [TILE_M-1:0];

    integer i, j;
    genvar gi, gj;
    generate
        for (gi=0; gi<TILE_M; gi=gi+1) begin
            assign wire_row_in[gi] = C_input[gi*TILE_N*DW_DATA +:TILE_N*DW_DATA];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<NUM_TILE; i=i+1) begin 
                reg_D_tile[i] <= 0;
            end
        end
        else begin
            if (write_outside_en) begin
                for (i=0; i<ITER_M; i=i+1) begin
                    reg_D_tile[row_in[3:2]*ITER_N+i][row_in[1:0]*TILE_N*DW_DATA +:TILE_N*DW_DATA] <= wire_row_in[i];
                end
            end
            if (write_inside_en) begin
                reg_D_tile[ptr_in] <= D_tile;
            end
        end
    end

    generate
        for (gi=0; gi<ITER_M; gi=gi+1) begin
            assign D_row_out[gi*TILE_N*DW_DATA +:TILE_N*DW_DATA] = reg_D_tile[row_out[3:2]*ITER_N+gi][row_out[1:0]*TILE_N*DW_DATA +:TILE_N*DW_DATA];
        end
    endgenerate

    assign C_tile = reg_D_tile[ptr_out];

endmodule