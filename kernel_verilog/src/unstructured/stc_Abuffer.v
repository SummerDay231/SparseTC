`timescale 1ns / 1ps

module stc_Abuffer #(
    parameter M = 16,
    parameter K = 16,
    parameter DW_MEM = 512,
    parameter DW_DATA = 32,
    parameter DW_COL = 4,
    parameter DW_PTR = 8
) (
    input clk,
    input reset,
    input write_data_en,
    input write_cidx_en,
    input [DW_MEM-1:0] A_data_input,
    input [DW_MEM-1:0] A_colidx_input,
    input [DW_COL-1:0] idx,
    input [DW_PTR*4-1:0] ptrs,
    output [DW_DATA*4-1:0] data,
    output [DW_COL*4-1:0] cols
);
    integer i, j;
    genvar gi;

    reg [K*DW_DATA-1:0] A_data [M-1:0];
    reg [K*DW_COL-1:0] A_col [M-1:0];
    wire [DW_COL-1:0] wire_rows [3:0];
    wire [DW_COL-1:0] wire_cols [3:0];

    generate
        for (gi=0; gi<4; gi=gi+1) begin
            assign wire_rows[gi] = ptrs[gi*DW_PTR+DW_COL +:DW_COL];
            assign wire_cols[gi] = ptrs[gi*DW_PTR +:DW_COL];
        end
    endgenerate
    
    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<M; i=i+1) begin
                A_data[i] <= 0;
                A_col[i] <= 0;
            end
        end
        else begin
            if (write_data_en) begin
                A_data[idx] <= A_data_input;
            end
            if (write_cidx_en) begin
                A_col[idx] <= A_colidx_input;
            end
        end
    end

    generate
        for (gi=0; gi<4; gi=gi+1) begin
            assign data[gi*DW_DATA +:DW_DATA] = A_data[wire_rows[gi]][wire_cols[gi]*DW_DATA +:DW_DATA];
            assign cols[gi*DW_COL +:DW_COL] = A_col[wire_rows[gi]][wire_cols[gi]*DW_COL +:DW_COL];
        end
    endgenerate

endmodule