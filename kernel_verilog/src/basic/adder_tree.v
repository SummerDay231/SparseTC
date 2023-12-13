`timescale 1ns / 1ps

module adder_tree #(
    parameter NUM_IN = 8,
    parameter N_STACK = 4,
    parameter DW_DATA = 32,
    parameter DW_LINE = N_STACK*DW_DATA
) (
    input clk,
    input rst,
    input [NUM_IN*DW_LINE-1:0] in,
    output [DW_LINE-1:0] out
);

    wire [DW_LINE-1:0] wire_in [NUM_IN-1:0];
    wire [DW_LINE-1:0] wire_lv2 [3:0];
    wire [DW_LINE-1:0] wire_lv3 [1:0];

    genvar gi;
    generate
        for (gi=0; gi<NUM_IN; gi=gi+1) begin
            assign wire_in[gi] = in[gi*DW_LINE +:DW_LINE];
        end
    endgenerate

    // wire_in[0] wire_in[1] wire_in[2] wire_in[3] wire_in[4] wire_in[5] wire_in[6] wire_in[7]
    //     adder_u_1_1           adder_u_1_2           adder_u_1_3           adder_u_1_4
    //     wire_lv2[0]           wire_lv2[1]           wire_lv2[2]           wire_lv2[3]
    //                adder_u_2_1                                 adder_u_2_2
    //                wire_lv3[0]                                 wire_lv3[1]
    //                                      adder_u_3_1
    //                                      out

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_1_1 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_in[0]),
        .in_b(wire_in[1]),
        .out(wire_lv2[0])
    );

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_1_2 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_in[2]),
        .in_b(wire_in[3]),
        .out(wire_lv2[1])
    );

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_1_3 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_in[4]),
        .in_b(wire_in[5]),
        .out(wire_lv2[2])
    );

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_1_4 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_in[6]),
        .in_b(wire_in[7]),
        .out(wire_lv2[3])
    );

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_2_1 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_lv2[0]),
        .in_b(wire_lv2[1]),
        .out(wire_lv3[0])
    );

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_2_2 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_lv2[2]),
        .in_b(wire_lv2[3]),
        .out(wire_lv3[1])
    );

    adder #(
        .N_STACK(N_STACK),
        .DW_DATA(DW_DATA)
    ) adder_u_3_1 (
        .clk(clk),
        .rst(rst),
        .in_a(wire_lv3[0]),
        .in_b(wire_lv3[1]),
        .out(out)
    );

endmodule

module adder #(
    parameter N_STACK = 4,
    parameter DW_DATA = 32
) (
    input clk,
    input rst,
    input [N_STACK*DW_DATA-1:0] in_a,
    input [N_STACK*DW_DATA-1:0] in_b,
    output [N_STACK*DW_DATA-1:0] out
);

    integer i;
    reg [DW_DATA-1:0] reg_out [N_STACK-1:0];

    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<N_STACK; i=i+1) begin
                reg_out[i] <= 0;
            end
        end
        else begin
            for (i=0; i<N_STACK; i=i+1) begin
                reg_out[i] <= in_a[i*DW_DATA +:DW_DATA] + in_b[i*DW_DATA +:DW_DATA];
            end
        end
    end

    genvar gi;
    generate
        for (gi=0; gi<N_STACK; gi=gi+1) begin
            assign out[gi*DW_DATA +:DW_DATA] = reg_out[gi];
        end
    endgenerate

endmodule