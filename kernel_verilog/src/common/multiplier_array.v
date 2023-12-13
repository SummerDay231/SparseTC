`timescale 1ns / 1ps

module multiplier_array #(
  parameter TILE_M = 4,
  parameter TILE_K = 8,
  parameter TILE_N = 4,
  parameter N_UNIT = TILE_M * TILE_K * TILE_N,
  parameter DW_IN = 8,
  parameter DW_OUT = DW_IN
)(
  input clk,
  input reset,
  input enable,
  input [N_UNIT*DW_IN-1:0]    in_a,
  input [N_UNIT*DW_IN-1:0]    in_b,
  input [1:0]                   in_valid,
  output [N_UNIT*DW_OUT-1:0]  out
);

  genvar gi;
  generate
    for (gi=0; gi<N_UNIT; gi=gi+1) begin: u_multi_unit
      multiply_unit #(
        .DW_IN(DW_IN),
        .DW_OUT(DW_OUT)
      )
      multi_unit_inst(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .in_a(in_a[gi*DW_IN +:DW_IN]),
        .in_b(in_b[gi*DW_IN +:DW_IN]),
        .in_valid(in_valid),
        .out(out[gi*DW_OUT +:DW_OUT])
      );
    end
  endgenerate

endmodule
