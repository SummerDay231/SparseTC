`timescale 1ns / 1ps

module tb_stc_pe();
parameter N = 8;
parameter DW_DATA = 8;

reg                  clk;
reg                  reset;
reg [DW_DATA-1:0]    A_element;
reg [N*DW_DATA-1:0]  B_row;
reg [N*DW_DATA-1:0]  C_row;
reg                  load_en;
reg                  acc_en;
wire [N*DW_DATA-1:0] D_row;

always #5 clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    load_en = 0;
    acc_en = 0;
    A_element = 0;
    B_row = 0;
    C_row = 64'b0;
    #10
    reset = 0;
    load_en = 1;
    A_element = 8'd1;
    B_row = {8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
    #10
    load_en = 0;
    A_element = 8'd2;
    B_row = {8'd0, 8'd3, 8'd5, 8'd4, 8'd7, 8'd2, 8'd8, 8'd0};
    #100 $finish;
end

stc_pe u_stc_pe(
    .clk(clk),
    .reset(reset),
    .A_element(A_element),
    .B_row(B_row),
    .C_row(C_row),
    .load_en(load_en),
    .acc_en(acc_en),
    .D_row(D_row)
);

endmodule