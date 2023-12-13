`timescale 1ns / 1ps

module stc_Bbuffer #(
    parameter N = 16,
    parameter K = 16,
    parameter DW_MEM = 512,
    parameter DW_IDX = 4,
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    input write_en,
    input [DW_MEM-1:0] B_input,
    input [DW_IDX-1:0] row,
    output [N*K*DW_DATA-1:0] B_rows
);

    reg [N*DW_DATA-1:0] reg_B [K-1:0];

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<K; i=i+1) begin
                reg_B[i] <= 0;
            end
        end
        else begin
            if (write_en) begin
                reg_B[row] <= B_input;
            end         
        end
    end

    genvar gi;
    generate
        for (gi=0; gi<K; gi=gi+1) begin
            assign B_rows[gi*N*DW_DATA +:N*DW_DATA] = reg_B[gi];
        end
    endgenerate

endmodule

