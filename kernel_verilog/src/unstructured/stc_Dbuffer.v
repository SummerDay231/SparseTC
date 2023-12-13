`timescale 1ns / 1ps

module stc_Dbuffer #(
    parameter M = 16,
    parameter N = 16,
    parameter N_PE = 4,
    parameter DW_MEM = 512,
    parameter DW_COL = 4,
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    // inside input
    input [N_PE-1:0] write_inside_en,
    input [N_PE*DW_COL-1:0] cols_in,
    input [N_PE*N*DW_DATA-1:0] D_rows,
    // inside output
    input [N_PE*DW_COL-1:0] cols_out,
    output [N_PE*N*DW_DATA-1:0] C_rows,
    // outside input 
    input write_outside_en,
    input [DW_COL-1:0] col_in,
    input [DW_MEM-1:0] C_input,
    // outside output
    input [DW_COL-1:0] col_out,
    output [N*DW_DATA-1:0] D_row_out
);

    reg [N*DW_DATA-1:0] reg_D [M-1:0];
    wire [DW_COL-1:0] wire_cols_in [N_PE-1:0];
    wire [DW_COL-1:0] wire_cols_out [N_PE-1:0];

    integer i, j;
    genvar gi, gj;
    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign wire_cols_in[gi] = cols_in[gi*DW_COL +:DW_COL];
            assign wire_cols_out[gi] = cols_out[gi*DW_COL +:DW_COL];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<M; i=i+1) begin 
                reg_D[i] <= 0;
            end
        end
        else begin
            if (write_outside_en) begin
                reg_D[col_in] <= C_input;
            end
            for (i=0; i<N_PE; i=i+1) begin
                if (write_inside_en[i]) begin
                    reg_D[wire_cols_in[i]] <= D_rows[i*N*DW_DATA +:N*DW_DATA];
                end
            end
        end
    end

    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign C_rows[gi*N*DW_DATA +:N*DW_DATA] = reg_D[wire_cols_out[gi]];
        end
    endgenerate

    assign D_row_out = reg_D[col_out];

endmodule