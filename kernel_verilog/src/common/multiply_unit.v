`timescale 1ns / 1ps

// dealy exists!
module multiply_unit #(
    parameter DW_IN = 8,
    parameter DW_OUT = 2*DW_IN
) (
    input clk,
    input reset,
    input enable,
    input signed [DW_IN-1:0] in_a,
    input signed [DW_IN-1:0] in_b,
    input [1:0] in_valid,
    output signed [DW_OUT-1:0] out
);

    reg signed [DW_IN-1:0] reg_multiplier_ia;
    reg signed [DW_IN-1:0] reg_multiplier_ib;
    reg signed [DW_OUT-1:0] reg_multiplier_o;

    always @(posedge clk) begin
        if (reset) begin
            reg_multiplier_ia <= 0;
            reg_multiplier_ib <= 0;
            reg_multiplier_o <= 0;
        end
        else if (enable) begin
            reg_multiplier_o <= reg_multiplier_ia * reg_multiplier_ib;

            if (in_valid[1] == 1'b1) begin : write_ia_block
                reg_multiplier_ia <= in_a;
            end
            if (in_valid[0] == 1'b1) begin : write_ib_block
                reg_multiplier_ib <= in_b;
            end
        end
    end

    assign out = reg_multiplier_o;

endmodule