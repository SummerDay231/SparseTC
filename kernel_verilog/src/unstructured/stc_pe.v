`timescale 1ns / 1ps

module stc_pe #(
    parameter N = 32,
    parameter DW_DATA = 8
) (
    input                  clk,
    input                  reset,
    input [DW_DATA-1:0]    A_element,
    input [N*DW_DATA-1:0]  B_row,
    input [N*DW_DATA-1:0]  C_row,
    input                  load_en,
    input                  acc_en,
    output [N*DW_DATA-1:0] D_row
);

    integer i;
    genvar gi;

    reg [N*DW_DATA-1:0] reg_psum;
    wire [N*DW_DATA-1:0] wire_mult_result, wire_add_result;

    always @(posedge clk) begin
        if (reset) reg_psum <= 0;
        else begin
            if (load_en) reg_psum <= C_row;
            else reg_psum <= wire_add_result;
        end
    end

    assign D_row = reg_psum;

    generate
        for (gi=0; gi<N; gi=gi+1) begin: u_multi_unit
            multiply_unit #(
                .DW_IN(DW_DATA),
                .DW_OUT(DW_DATA)
            )
            multi_unit_inst(
                .clk(clk),
                .reset(reset),
                .enable(1),
                .in_a(A_element),
                .in_b(B_row[gi*DW_DATA +:DW_DATA]),
                .in_valid(2'b11),
                .out(wire_mult_result[gi*DW_DATA +:DW_DATA])
            );
        end

        for (gi=0; gi<N; gi=gi+1) begin: u_add_unit
            instant_adder #(
                .N_STACK(N),
                .DW_DATA(DW_DATA)
            ) 
            instant_adder_inst(
                .in_a(wire_mult_result),
                .in_b(reg_psum),
                .out(wire_add_result)
            );
        end
    endgenerate

endmodule