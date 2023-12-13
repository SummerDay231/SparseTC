`timescale 1ns / 1ps

module tc_array #(
    parameter TILE_M = 4,
    parameter TILE_K = 8,
    parameter TILE_N = 4,
    parameter N_UNIT = TILE_M * TILE_K * TILE_N,
    parameter DW_IN = 8,
    parameter DW_OUT = 8,
    parameter DW_MULT = DW_IN
) (
    input clk,
    input reset,
    // input 
    input [TILE_M*TILE_K*DW_IN-1:0] in_a, 
    input [TILE_N*TILE_K*DW_IN-1:0] in_b,
    // output
    output [TILE_M*TILE_N*DW_OUT-1:0] out
);

    wire [N_UNIT*DW_IN-1:0] wire_a;
    wire [N_UNIT*DW_IN-1:0] wire_b;
    wire [N_UNIT*DW_MULT-1:0] wire_dp_out;
    wire [N_UNIT*DW_OUT-1:0] wire_rn_in;
    
    tc_dn #(
        .DW_DATA(DW_IN)
    ) tc_dn_u (
        .in_a(in_a),
        .in_b(in_b),
        .out_a(wire_a),
        .out_b(wire_b)
    );

    multiplier_array #(
        .TILE_M(TILE_M),
        .TILE_K(TILE_K),
        .TILE_N(TILE_N),
        .DW_IN(DW_IN)
    ) u_dp_group (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in_a(wire_a),
        .in_b(wire_b),
        .in_valid(2'b11),
        .out(wire_dp_out)
    );

    genvar gi;
    generate
        for (gi=0; gi<N_UNIT; gi=gi+1) begin
            assign wire_rn_in[gi*DW_OUT +:DW_OUT] = {wire_dp_out[gi*DW_MULT +:DW_MULT]}; // TODO: sign kuozhan 
        end
    endgenerate

    tc_rn #(
        .DW_DATA(DW_OUT)
    ) u_tc_rn (
        .clk(clk),
        .rst(rst),
        .in(wire_rn_in),
        .out(out)
    );

endmodule

module tc_dn #(
    parameter TILE_M = 4,
    parameter TILE_K = 8,
    parameter TILE_N = 4,
    parameter N_UNIT = TILE_M * TILE_K * TILE_N,
    parameter DW_DATA = 8
) (
    input [TILE_M*TILE_K*DW_DATA-1:0] in_a, 
    input [TILE_N*TILE_K*DW_DATA-1:0] in_b,
    output [N_UNIT*DW_DATA-1:0] out_a,
    output [N_UNIT*DW_DATA-1:0] out_b
);

    genvar gi;
    generate
        for (gi=0; gi<TILE_M*TILE_K; gi=gi+1) begin
            assign out_a[gi*TILE_N*DW_DATA +:TILE_N*DW_DATA] = {TILE_N{in_a[gi*DW_DATA +:DW_DATA]}};
        end
    endgenerate

    assign out_b = {TILE_M{in_b}};

endmodule