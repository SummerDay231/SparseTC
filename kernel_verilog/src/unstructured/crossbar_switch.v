`timescale 1ns / 1ps

module crossbar_switch #(
    parameter DW_DATA = 8
) (
    input clk,
    input reset,
    input ctrl,
    input [2*DW_DATA-1:0] in, // 0 is left input, 1 is up input
    output reg [2*DW_DATA-1:0] out // 0 is right output, 1 is down output
);

    always @(*) begin 
        if (reset) begin
            out <= 0;
        end
        else if (ctrl) begin
            out <= {in[0 +:DW_DATA], in[0 +:DW_DATA]};
        end
        else begin
            out <= in;
        end
    end

endmodule