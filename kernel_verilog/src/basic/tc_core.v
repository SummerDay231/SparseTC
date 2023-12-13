`timescale 1ns / 1ps

module tc_core #(
    parameter M = 32,
    parameter N = 32,
    parameter K = 32,
    parameter TILE_M = 4,
    parameter TILE_K = 8,
    parameter TILE_N = 4,
    parameter iterM = M / TILE_M,
    parameter iterN = N / TILE_N,
    parameter iterK = K / TILE_K,
    parameter N_UNIT = TILE_M * TILE_K * TILE_N,
    parameter DW_IN = 8,
    parameter DW_POS = 4,
    parameter DW_OUT = 8
) (
    input clk,
    input reset,
    input load_en,
    input compute_en,
    input [M*K*DW_IN-1:0] in_a,
    input [K*N*DW_IN-1:0] in_b,
    output [M*N*DW_OUT-1:0] out
);

    parameter IDLE = 2'd0;
    parameter LOAD = 2'd1;
    parameter COMPUTE = 2'd2;
    integer i, j;
    genvar gi, gj;
    
    reg [1:0] state, next_state;

    reg [DW_IN-1:0] reg_a [M-1:0][K-1:0];
    reg [DW_IN-1:0] reg_b [K-1:0][N-1:0];
    reg [DW_IN-1:0] reg_tile_a [TILE_M-1:0][TILE_K-1:0];
    reg [DW_IN-1:0] reg_tile_b [TILE_K-1:0][TILE_N-1:0];
    reg [3:0]  ptr_m, ptr_n, ptr_k;
    reg out_en, input_en;

    wire [TILE_M*TILE_K*DW_IN-1:0] wire_tile_a;
    wire [TILE_N*TILE_K*DW_IN-1:0] wire_tile_b;
    wire [TILE_M*TILE_N*DW_OUT-1:0] wire_compute_result;
    wire [3:0] col_n, row_m;
    wire out_valid, col_valid, row_valid, psum_input_en, psum_input_en_valid;

    // state transfer and control
    always @(posedge clk) begin
        if (reset) begin
            next_state <= IDLE;
            out_en <= 0;
            input_en <= 0;
        end
        else begin
            if (load_en != 0)
                next_state <= 1;
            else if (compute_en) begin
                next_state <= COMPUTE;
                input_en <= 1;
            end
            if (state==LOAD) begin
                for (i=0; i<M; i=i+1) begin
                    for (j=0; j<K; j=j+1) begin
                        reg_a[i][j] <= in_a[(i*K+j)*DW_IN +:DW_IN];
                    end
                end
                for (i=0; i<K; i=i+1) begin
                    for (j=0; j<N; j=j+1) begin
                        reg_b[i][j] <= in_b[(i*N+j)*DW_IN +:DW_IN];
                    end
                end
                ptr_m <= 0;
                ptr_n <= 0;
                ptr_k <= 0;
            end
            else if (state==COMPUTE) begin
                if (ptr_m == M - TILE_M) begin
                    if (ptr_k == K - TILE_K) begin
                        if (ptr_n == N - TILE_N) begin
                            next_state <= IDLE;
                        end
                        else begin
                            ptr_m <= 0;
                            ptr_k <= 0;
                            ptr_n <= ptr_n+TILE_N;
                        end
                    end
                    else begin
                        ptr_m <= 0;
                        ptr_k <= ptr_k + TILE_K;
                    end
                end
                else begin
                    ptr_m <= ptr_m + TILE_M;
                end
            end
        end
    end

    // select tile
    always @(posedge clk) begin: a1
        for (i=0; i<TILE_M; i=i+1) begin
            for (j=0; j<TILE_K; j=j+1) begin
                reg_tile_a[i][j] <= reg_a[ptr_m+i][ptr_k+j];
            end
        end
        for (i=0; i<TILE_K; i=i+1) begin
            for (j=0; j<TILE_N; j=j+1) begin
                reg_tile_b[i][j] <= reg_b[ptr_k+i][ptr_n+j];
            end
        end
    end

    always @(posedge clk) begin
        state <= next_state;
    end

    generate
        for (gi=0; gi<TILE_M; gi=gi+1) begin
            for (gj=0; gj<TILE_K; gj=gj+1) begin
                assign wire_tile_a[(gi*TILE_K+gj)*DW_IN +:DW_IN] = reg_tile_a[gi][gj];
            end
        end
        for (gi=0; gi<TILE_K; gi=gi+1) begin
            for (gj=0; gj<TILE_N; gj=gj+1) begin
                assign wire_tile_b[(gi*TILE_N+gj)*DW_IN +:DW_IN] = reg_tile_b[gi][gj];
            end
        end
    endgenerate

delay_unit #(
    .DW_DATA(DW_POS),
    .W_SHIFT(6)
) u_delay_col (
    .clk(clk),
    .reset(reset),
    .enable(1),
    .in(ptr_n),
    .out_valid(col_valid),
    .out(col_n)
);
delay_unit #(
    .DW_DATA(DW_POS),
    .W_SHIFT(6)
) u_delay_row (
    .clk(clk),
    .reset(reset),
    .enable(1),
    .in(ptr_m),
    .out_valid(row_valid),
    .out(row_m)
);
delay_unit #(
    .DW_DATA(1),
    .W_SHIFT(6)
) u_delay_input_en (
    .clk(clk),
    .reset(reset),
    .enable(1),
    .in(input_en),
    .out_valid(psum_input_en_valid),
    .out(psum_input_en)
);

tc_array u_tc_array (
    .clk(clk),
    .reset(reset),
    .in_a(wire_tile_a),
    .in_b(wire_tile_b),
    .out(wire_compute_result)
);

tc_psum #(
    .M(M),
    .N(N),
    .TILE_M(TILE_M),
    .TILE_N(TILE_N),
    .DW_DATA(DW_OUT)
) u_tc_psum(
    .clk(clk),
    .rst(reset),
    .col(col_n),
    .row(row_m),
    .in(wire_compute_result),
    .input_en(psum_input_en),
    .out_en(out_en),
    .out_valid(out_valid),
    .out(out)
);

endmodule