`timescale 1ns / 1ps

module stc_core #(
    parameter M = 16,
    parameter K = 16,
    parameter N = 16,
    parameter N_PE = 4,
    parameter DW_MEM = 512,
    parameter DW_DATA = 32,
    parameter DW_IDX = 4,
    parameter DW_PTR = 8
) (
    input clk,
    input reset,
    // cu input
    input write_cu,
    input [DW_MEM-1:0] cu_input,
    // a input
    input write_a_data_en,
    input write_a_cidx_en,
    input [DW_MEM-1:0] A_data_input,
    input [DW_MEM-1:0] A_colidx_input,
    input [DW_IDX-1:0] A_idx,
    // b input
    input write_b,
    input [DW_MEM-1:0] B_input,
    input [DW_IDX-1:0] B_row,
    // c input
    input write_c,
    input [N*DW_DATA-1:0] in_c,
    input [DW_IDX-1:0] in_c_row,
    // output
    output out_valid,
    output [N*DW_DATA-1:0] out_d
);

    wire [N_PE*DW_PTR-1:0] wire_ptrs;
    wire [N_PE*DW_IDX-1:0] wire_rows;
    wire [N_PE-1:0] wire_acc_en;
    wire [N_PE-1:0] wire_write_D_en;
    wire [DW_IDX-1:0] wire_row_out;
    
    wire [N_PE*DW_DATA-1:0] wire_a_data;
    wire [N_PE*DW_IDX-1:0] wire_a_cols;
    wire [N*K*DW_DATA-1:0] wire_b_data;
    wire [N_PE*N*DW_DATA-1:0] wire_pe_in_a;
    wire [N_PE*N*DW_DATA-1:0] wire_pe_in_b;
    wire [N*DW_DATA-1:0] wire_pe_in_b_split [N_PE-1:0];
    wire [N_PE*N*DW_DATA-1:0] wire_pe_out;
    wire [N*DW_DATA-1:0] wire_pe_out_split [N_PE-1:0];

    wire [N_PE-1:0] wire_accumu_en;

    wire [N_PE*N*DW_DATA-1:0] wire_in_c;
    wire [N*DW_DATA-1:0] wire_in_c_split [N_PE-1:0];
    wire [N_PE*N*DW_DATA-1:0] wire_out_c;
    wire [N_PE-1:0] wire_write_D_en_delay;
    wire [N_PE*DW_IDX-1:0] wire_D_rows;
    wire [N_PE*DW_IDX-1:0] wire_C_out_rows;
    wire [DW_IDX-1:0] wire_D_row_out;
    wire cu_outvalid;

    genvar gi;
    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign wire_pe_in_b_split[gi] = wire_pe_in_b[gi*N*DW_DATA +:N*DW_DATA];
            assign wire_pe_out_split[gi] = wire_pe_out[gi*N*DW_DATA +:N*DW_DATA];
            assign wire_in_c_split[gi] = wire_in_c[gi*N*DW_DATA +:N*DW_DATA];
        end
    endgenerate

    stc_cu #(
        .M(M),
        .DW_ROWIDX(DW_IDX),
        .DW_ELEIDX(DW_PTR),
        .N_PE(N_PE),
        .DW_DATA(DW_DATA)
    ) u_cu(
        .clk(clk),
        .reset(reset),
        .write_en(write_cu),
        .cu_input(cu_input),
        .A_ptrs(wire_ptrs),
        .A_rows(wire_rows),
        .acc_en(wire_acc_en),
        .write_D_en(wire_write_D_en),
        .row_out(wire_row_out),
        .out_valid(cu_outvalid)
    );

    stc_Abuffer #(
        .M(M),
        .K(K),
        .DW_DATA(DW_DATA),
        .DW_COL(DW_IDX),
        .DW_PTR(DW_PTR)
    ) u_Abuffer(
        .clk(clk),
        .reset(reset),
        .write_data_en(write_a_data_en),
        .write_cidx_en(write_a_cidx_en),
        .A_data_input(A_data_input),
        .A_colidx_input(A_colidx_input),
        .idx(A_idx),
        .ptrs(wire_ptrs),
        .data(wire_a_data),
        .cols(wire_a_cols)
    );

    stc_Bbuffer #(
        .N(N),
        .K(K),
        .DW_DATA(DW_DATA)
    ) u_Bbuffer(
        .clk(clk),
        .reset(reset),
        .write_en(write_b),
        .B_input(B_input),
        .row(B_row),
        .B_rows(wire_b_data)
    );

    stc_A_DN #(
        .N(N),
        .DW_DATA(DW_DATA),
        .N_PE(N_PE)
    ) u_A_DN(
        .clk(clk),
        .reset(reset),
        .in_a(wire_a_data),
        .out_a(wire_pe_in_a)
    );

    stc_B_DN #(
        .K(K),
        .N(N),
        .N_PE(N_PE),
        .DW_DATA(DW_DATA),
        .DW_COL(DW_IDX)
    ) u_B_DN(
        .clk(clk),
        .reset(reset),
        .in_b(wire_b_data),
        .in_cols(wire_a_cols),
        .out_b(wire_pe_in_b)
    );

    stc_pe_array #(
        .N_PE(N_PE),
        .N(N),
        .DW_DATA(DW_DATA)
    ) u_pe_array(
        .clk(clk),
        .reset(reset),
        .in_a(wire_pe_in_a),
        .in_b(wire_pe_in_b),
        .out(wire_pe_out)
    );

    stc_accumulator #(
        .N_PE(N_PE),
        .N(N),
        .DW_DATA(DW_DATA)
    ) u_accumulator(
        .clk(clk),
        .reset(reset),
        .acc_en(wire_accumu_en),
        .in_mult(wire_pe_out),
        .in_psum(wire_out_c),
        .out(wire_in_c)
    );

    stc_Dbuffer #(
        .M(M),
        .N(N),
        .N_PE(N_PE),
        .DW_COL(DW_IDX),
        .DW_DATA(DW_DATA)
    ) u_Dbuffer(
        .clk(clk),
        .reset(reset),
        .cols_in(wire_D_rows),
        .D_rows(wire_in_c),
        .write_inside_en(wire_write_D_en_delay),
        .cols_out(wire_C_out_rows),
        .C_rows(wire_out_c),
        .write_outside_en(write_c),
        .col_in(in_c_row),
        .C_input(in_c),
        .col_out(wire_D_row_out),
        .D_row_out(out_d)
    );

    delay_unit #(
        .DW_DATA(N_PE*DW_IDX),
        .W_SHIFT(2)
    ) u_delay_c_out_row (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(wire_rows),
        .out_valid(),
        .out(wire_C_out_rows)
    );

    delay_unit #(
        .DW_DATA(N_PE),
        .W_SHIFT(2)
    ) u_delay_acc_en (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(wire_acc_en),
        .out_valid(),
        .out(wire_accumu_en)
    );

    delay_unit #(
        .DW_DATA(N_PE),
        .W_SHIFT(2)
    ) u_delay_write_d_en (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(wire_write_D_en),
        .out_valid(),
        .out(wire_write_D_en_delay)
    );

    delay_unit #(
        .DW_DATA(N_PE*DW_IDX),
        .W_SHIFT(3)
    ) u_delay_D_rows (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(wire_rows),
        .out_valid(),
        .out(wire_D_rows)
    );

    delay_unit #(
        .DW_DATA(DW_IDX),
        .W_SHIFT(3)
    ) u_delay_D_row_out (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(wire_row_out),
        .out_valid(),
        .out(wire_D_row_out)
    );

    delay_unit #(
        .DW_DATA(1),
        .W_SHIFT(3)
    ) u_delay_outvalid (
        .clk(clk),
        .reset(reset),
        .enable(1),
        .in(cu_outvalid),
        .out_valid(),
        .out(out_valid)
    );

endmodule