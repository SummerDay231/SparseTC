`timescale 1ns / 1ps

module tc_cu #(
    parameter M = 16,
    parameter N = 16,
    parameter K = 16,
    parameter TILE_M = 4,
    parameter TILE_K = 4,
    parameter TILE_N = 4,
    parameter iterM = M / TILE_M,
    parameter iterN = N / TILE_N,
    parameter iterK = K / TILE_K,
    parameter N_UNIT = TILE_M * TILE_K * TILE_N
) (
    input clk,
    input reset,
    input load_en,
    input compute_en,
    // input [M*K*DW_IN-1:0] in_a,
    // input [K*N*DW_IN-1:0] in_b,
    output [3:0] ptr_m,
    output [3:0] ptr_n,
    output [3:0] ptr_k,
    output write_d,
    output out_valid,
    output [3:0] row_out
);

    parameter IDLE = 2'd0;
    parameter LOAD = 2'd1;
    parameter COMPUTE = 2'd2;
    parameter OUTPUT = 2'd3;
    integer i, j;
    genvar gi, gj;
    
    reg [1:0] state, next_state;

    // reg [DW_IN-1:0] reg_a [M-1:0][K-1:0];
    // reg [DW_IN-1:0] reg_b [K-1:0][N-1:0];
    // reg [DW_IN-1:0] reg_tile_a [TILE_M-1:0][TILE_K-1:0];
    // reg [DW_IN-1:0] reg_tile_b [TILE_K-1:0][TILE_N-1:0];
    reg [3:0]  reg_ptr_m, reg_ptr_n, reg_ptr_k, reg_row_out;
    reg out_en;

    // state transfer and control
    always @(posedge clk) begin
        if (reset) begin
            out_en <= 0;
            reg_ptr_m <= 0;
            reg_ptr_n <= 0;
            reg_ptr_k <= 0;
            reg_row_out = 4'b1111;
        end
        else begin
            if (state==LOAD) begin
                // for (i=0; i<M; i=i+1) begin
                //     for (j=0; j<K; j=j+1) begin
                //         reg_a[i][j] <= in_a[(i*K+j)*DW_IN +:DW_IN];
                //     end
                // end
                // for (i=0; i<K; i=i+1) begin
                //     for (j=0; j<N; j=j+1) begin
                //         reg_b[i][j] <= in_b[(i*N+j)*DW_IN +:DW_IN];
                //     end
                // end
                reg_ptr_m <= 0;
                reg_ptr_n <= 0;
                reg_ptr_k <= 0;
            end
            else if (state==COMPUTE) begin
                if (reg_ptr_m == M - TILE_M) begin
                    if (reg_ptr_k == K - TILE_K) begin
                        if (reg_ptr_n == N - TILE_N) begin
                            //next_state <= IDLE;
                            reg_row_out <= 0;
                        end
                        else begin
                            reg_ptr_m <= 0;
                            reg_ptr_k <= 0;
                            reg_ptr_n <= reg_ptr_n+TILE_N;
                        end
                    end
                    else begin
                        reg_ptr_m <= 0;
                        reg_ptr_k <= reg_ptr_k + TILE_K;
                    end
                end
                else begin
                    reg_ptr_m <= reg_ptr_m + TILE_M;
                end
            end
            else if (state == OUTPUT) begin
                reg_row_out <= reg_row_out + 1;
            end
        end
    end

    always @(*) begin
        if (reset) begin
            next_state = IDLE;
        end
        else if (load_en != 0)
            next_state = LOAD;
        else if (state == LOAD && compute_en) begin
            next_state = COMPUTE;
        end
        else if (state == COMPUTE && reg_ptr_m == M - TILE_M && reg_ptr_k == K - TILE_K && reg_ptr_n == N - TILE_N) begin
            next_state = OUTPUT;
        end
        else if (state == OUTPUT && reg_row_out == 15) begin
            next_state = IDLE;
        end
    end

    // select tile
    // always @(posedge clk) begin: a1
    //     for (i=0; i<TILE_M; i=i+1) begin
    //         for (j=0; j<TILE_K; j=j+1) begin
    //             reg_tile_a[i][j] <= reg_a[ptr_m+i][ptr_k+j];
    //         end
    //     end
    //     for (i=0; i<TILE_K; i=i+1) begin
    //         for (j=0; j<TILE_N; j=j+1) begin
    //             reg_tile_b[i][j] <= reg_b[ptr_k+i][ptr_n+j];
    //         end
    //     end
    // end

    always @(posedge clk) begin
        state <= next_state;
    end

    assign ptr_m = reg_ptr_m;
    assign ptr_n = reg_ptr_n;
    assign ptr_k = reg_ptr_k;
    assign write_d = (state == COMPUTE);
    assign row_out = reg_row_out;
    assign out_valid = (state == OUTPUT);

endmodule
