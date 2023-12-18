`timescale 1ns / 1ps

module tc_mergetree#(
    parameter N_UNIT = 64,
    parameter N_MERGE = 16,
    parameter TILE_K = 4,
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    input [N_UNIT*DW_DATA-1:0] in_mult,
    input [N_MERGE*DW_DATA-1:0] in_psum,
    output [N_MERGE*DW_DATA-1:0] out
);

    wire [N_MERGE*DW_DATA-1:0] merge_result;
    wire [N_MERGE*DW_DATA-1:0] delayed_psum;
    reg [N_MERGE*DW_DATA-1:0] reg_out;

    integer i;
    genvar gi;
    generate
        for (gi=0; gi<N_MERGE; gi=gi+1) begin
            adder_tree #(
                .DW_DATA(DW_DATA)
            ) u_adder (
                .clk(clk),
                .reset(reset),
                .in(in_mult[gi*4*DW_DATA +:4*DW_DATA]),
                .out(merge_result[gi*DW_DATA +:DW_DATA])
            );
        end
    endgenerate

    delay_unit #(
        .DW_DATA(N_MERGE*DW_DATA),
        .W_SHIFT(2)
    ) u_delay(
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(in_psum),
        .out(delayed_psum)
    );

    always @(posedge clk) begin
        if (reset) begin
            reg_out <= 0;
        end
        else begin
            for (i=0; i<N_MERGE; i=i+1) begin
                reg_out[i*DW_DATA +:DW_DATA] <= merge_result[i*DW_DATA +:DW_DATA] + delayed_psum[i*DW_DATA +:DW_DATA];
            end
        end
    end

    assign out = reg_out;

endmodule

module adder_tree #(
    parameter DW_DATA = 32
) (
    input clk,
    input reset,
    input [4*DW_DATA-1:0] in,
    output [DW_DATA-1:0] out
);

    reg [DW_DATA-1:0] lv1_result [1:0];
    reg [DW_DATA-1:0] lv2_result;

    always @(posedge clk) begin
        if (reset) begin
            lv1_result[0] <= 0;
            lv1_result[1] <= 0;
            lv2_result <= 0;
        end
        else begin
            lv1_result[0] <= in[0*DW_DATA +:DW_DATA] + in[1*DW_DATA +:DW_DATA];
            lv1_result[1] <= in[2*DW_DATA +:DW_DATA] + in[3*DW_DATA +:DW_DATA];
            lv2_result <= lv1_result[0] + lv1_result[1];
        end
    end
    
    assign out = lv2_result;

endmodule