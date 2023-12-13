`timescale 1ns / 1ps

module stc_accumulator #(
    parameter N_PE = 4,
    parameter N = 16,
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    input [N_PE*N*DW_DATA-1:0] in_mult,
    input [N_PE*N*DW_DATA-1:0] in_psum,
    input [N_PE-1:0] acc_en,
    output [N_PE*N*DW_DATA-1:0] out
);

    genvar gi;
    integer i, j;

    reg [N*DW_DATA-1:0] reg_psum [N_PE-1:0];
    
    wire [N*DW_DATA-1:0] wire_in_psum [N_PE-1:0];
    wire [N*DW_DATA-1:0] wire_in_mult [N_PE-1:0];
    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign wire_in_psum[gi] = in_psum[gi*N*DW_DATA +:N*DW_DATA];
            assign wire_in_mult[gi] = in_mult[gi*N*DW_DATA +:N*DW_DATA];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<N_PE; i=i+1) begin
                reg_psum[i] <= 0;
            end
        end
        else begin
            for (i=0; i<N_PE; i=i+1) begin
                if (acc_en[i]) begin
                    for (j=0; j<N; j=j+1) begin
                        reg_psum[i][j*DW_DATA +:DW_DATA] <= in_psum[(i*N+j)*DW_DATA +:DW_DATA] + in_mult[(i*N+j)*DW_DATA +:DW_DATA];
                    end
                end
                else begin
                    for (j=0; j<N; j=j+1) begin
                        reg_psum[i][j*DW_DATA +:DW_DATA] <= reg_psum[i][j*DW_DATA +:DW_DATA] + in_mult[(i*N+j)*DW_DATA +:DW_DATA];
                    end
                end
            end
        end
    end

    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign out[gi*N*DW_DATA +:N*DW_DATA] = reg_psum[gi];
        end
    endgenerate

endmodule