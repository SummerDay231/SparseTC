`timescale 1ns / 1ps

module tc_core #(
    parameter M = 16,
    parameter N = 16,
    parameter K = 16,
    parameter TILE_M = 4,
    parameter TILE_N = 4,
    parameter TILE_K = 4,
    parameter TILE_SIZE = 16,
    parameter NUM_TILE = 16,
    parameter N_PE = 4,
    parameter N_UNIT = 64,
    parameter DW_DATA = 32,
    parameter DW_IDX = 4,
    parameter DW_MEM = 512
) (
    input clk,
    input reset,
    // control signal
    input load_en,
    input compute_en,
    // A input
    input write_a,
    input [DW_MEM-1:0] A_input,
    input [DW_IDX-1:0] A_row,
    // B input
    input write_b,
    input [DW_MEM-1:0] B_input,
    input [DW_IDX-1:0] B_row,
    // C input
    input write_c,
    input [DW_MEM-1:0] C_input,
    input [DW_IDX-1:0] C_row,
    // D output
    output out_valid,
    output [DW_MEM-1:0] D_row_out
);

    wire write_d;
    wire [DW_IDX-1:0] ptr_m, ptr_k, ptr_n, D_row;
    wire [DW_IDX-1:0] ptr_A, ptr_B, ptr_C, ptr_D;
    wire [TILE_SIZE*DW_DATA-1:0] A_tile, B_tile, C_tile, D_tile;
    wire [N_UNIT*DW_DATA-1:0] mult_A, mult_B, mult_result;

    assign ptr_A = {ptr_m[3:2], ptr_k[3:2]};
    assign ptr_B = {ptr_k[3:2], ptr_n[3:2]};
    assign ptr_C = {ptr_m[3:2], ptr_n[3:2]};


    tc_cu #(
        .M(M)
    ) u_cu (
        .clk(clk),
        .reset(reset),
        .load_en(load_en),
        .compute_en(compute_en),
        .ptr_m(ptr_m),
        .ptr_k(ptr_k),
        .ptr_n(ptr_n),
        .write_d(write_d),
        .out_valid(out_valid),
        .row_out(D_row)
    );

    tc_Abuffer #(
        .DW_DATA(DW_DATA)
    ) u_Abuf (
        .clk(clk),
        .reset(reset),
        .write_en(write_a),
        .A_input(A_input),
        .row_in(A_row),
        .ptr_out(ptr_A),
        .A_tile(A_tile)
    );

    tc_Bbuffer #(
        .DW_DATA(DW_DATA)
    ) u_Bbuf (
        .clk(clk),
        .reset(reset),
        .write_en(write_b),
        .B_input(B_input),
        .row_in(B_row),
        .ptr_out(ptr_B),
        .B_tile(B_tile)
    );

    tc_A_DN #(
        .DW_DATA(DW_DATA)
    ) u_A_DN (
        .clk(clk),
        .reset(reset),
        .in_a(A_tile),
        .out_a(mult_A)
    );

    tc_B_DN #(
        .DW_DATA(DW_DATA)
    ) u_B_DN (
        .clk(clk),
        .reset(reset),
        .in_b(B_tile),
        .out_b(mult_B)
    );

    tc_pe_array #(
        .DW_DATA(DW_DATA)
    ) u_pearray (
        .clk(clk),
        .reset(reset),
        .in_a(mult_A),
        .in_b(mult_B),
        .out(mult_result)
    );

    tc_mergetree #(
        .DW_DATA(DW_DATA)
    ) u_mt (
        .clk(clk),
        .reset(reset),
        .in_mult(mult_result),
        .in_psum(C_tile),
        .out(D_tile)
    );

    tc_Dbuffer #(
        .DW_DATA(DW_DATA)
    ) u_Dbuf(
        .clk(clk),
        .reset(reset),
        .write_inside_en(write_d),
        .ptr_in(ptr_D),
        .D_tile(D_tile),
        .ptr_out(ptr_C),
        .C_tile(C_tile),
        .write_outside_en(write_c),
        .row_in(C_row),
        .C_input(C_input),
        .row_out(D_row),
        .D_row_out(D_row_out)
    );

endmodule