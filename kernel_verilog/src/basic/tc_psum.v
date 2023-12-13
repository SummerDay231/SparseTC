`timescale 1ns / 1ps

////////////////////////////////////////////////////////////
// 文件名：tc_psum.v
// 模块功能描述：模块包含一个register file，用于储存矩阵乘法的结果（一个M*N的矩阵），以及将规约网络的输出结果累加到对应数值上
//             即：保存一个M*N的矩阵，能够根据输入的地址信息（行首的位置和列首的位置），读取某些位置的数据（一个规整的块），
//             并将输入数据与其相加，将结果写回到原位置上
// 具体行为描述：rst拉高时，所有register file全部置零
//             共有三个register file：
//             * 一个M*N的reg_cache，用于存放矩阵
//             * 一个M*TILE_N的reg_add，存放输出矩阵的部分列，也就是要累加的数据，具体来说是[col, col+TILE_N-1]这部分列，
//             累加后的数据写到这里（具体来说是[row, row+TILE_M-1]这部分行），然后统一写回到reg_cache（这样设计是为了避免
//             反复读取较大的reg_cache，用多余的reg降低开销，且数据流决定了会一行一行完成部分列，再一行一行完成下一部分列）
//             * 一个reg_col，用于存储上个周期的col信号，当reg_col与col不一致时，说明reg_add要写回reg_cache，并更新reg_add
////////////////////////////////////////////////////////////

module tc_psum #(
    parameter M = 16,                   // 输出矩阵的行数
    parameter N = 16,                   // 输出矩阵的列数
    parameter TILE_M = 4,               // 一次累加操作会涉及到的行数（连续的）
    parameter TILE_N = 4,               // 一次累加操作会涉及到的列数（连续的）
    parameter NUM_IN = TILE_M * TILE_N, // 一次累加操作会涉及到的操作数
    parameter DW_DATA = 8,             // 数据位宽
    parameter DW_POS = 4,               // 位置信息的位宽
    parameter NUM_OUT = M * N,          // 输出大小（这里设置是一次输出整个矩阵）
    parameter DW_OUT = NUM_OUT*DW_DATA  // 输出位宽
) (
    input clk,
    input rst,
    input [DW_POS-1:0] col,
    input [DW_POS-1:0] row,
    input [NUM_IN*DW_DATA-1:0] in,
    input input_en,
    input out_en,
    output out_valid,
    output [DW_OUT-1:0] out
);
    reg [DW_DATA-1:0] reg_cache [M-1:0][N-1:0];
    reg [DW_DATA-1:0] reg_add [M-1:0][TILE_N-1:0];
    reg [DW_POS-1:0] reg_col;

    wire [DW_DATA-1:0] wire_in [TILE_M-1:0][TILE_N-1:0];

    genvar gi, gj;
    generate
        for (gi=0; gi<TILE_M; gi=gi+1) begin
            for (gj=0; gj<TILE_N; gj=gj+1) begin
                assign wire_in[gi][gj] = in[(gi*TILE_N+gj)*DW_DATA +:DW_DATA];
            end
        end
    endgenerate

    // set reg pos
    always @(posedge clk) begin
        if (rst) begin
            reg_col <= 0;
        end
        else if (input_en) begin
            reg_col <= col;
        end
        else begin
            reg_col <= 0;
        end
    end


    // reg cache
    integer i, j;
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<M; i=i+1) begin
                for (j=0; j<N; j=j+1) begin
                    reg_cache[i][j] <= 0;
                end
            end
        end
        else if (col != reg_col) begin
            for (i=0; i<M; i=i+1) begin
                for (j=0; j<TILE_N; j=j+1) begin
                    reg_cache[i][reg_col+j] <= reg_add[i][j];
                end
            end
        end
    end

    // reg add
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<M; i=i+1) begin
                for (j=0; j<TILE_N; j=j+1) begin
                    reg_add[i][j] <= 0;
                end
            end
        end
        else if (col == reg_col) begin // accumulate
            for (i=0; i<TILE_M; i=i+1) begin
                for (j=0; j<TILE_N; j=j+1) begin
                    reg_add[row+i][j] <= reg_add[row+i][j] + wire_in[i][j];
                end
            end
        end
        else begin // fresh line
            for (i=0; i<M; i=i+1) begin
                for (j=0; j<TILE_N; j=j+1) begin
                    reg_add[i][j] <= 0;
                end
            end
        end
    end

    generate
        for (gi=0; gi<M; gi=gi+1) begin
            for (gj=0; gj<N; gj=gj+1) begin
                assign out[(gi*N+gj)*DW_DATA +:DW_DATA] = reg_cache[gi][gj];
            end
        end
    endgenerate
    assign out_valid = out_en;

endmodule