`timescale 1ns / 1ps

module stc_cu #(
    parameter M = 16,
    parameter DW_MEM = 512,
    parameter DW_ROWIDX = 4,
    parameter DW_ELEIDX = 8,
    parameter N_PE = 4,
    parameter DW_DATA = 8,
    parameter DW_ROWPTR = (M+1)*DW_ELEIDX,
    parameter DW_ROW2ROW = M*DW_ROWIDX,
    parameter DW_WKLDPTR = N_PE*DW_ROWIDX
) (
    input clk,
    input reset,
    input write_en,
    input [DW_MEM-1:0] cu_input,
    output [N_PE*DW_ELEIDX-1:0] A_ptrs,
    output [N_PE-1:0] acc_en,
    output [N_PE-1:0] write_D_en,
    output [N_PE*DW_ROWIDX-1:0] A_rows,
    output out_valid,
    output [DW_ROWIDX-1:0] row_out
);

    parameter IDLE = 0;
    parameter FIRST_ROW_START = 1;
    parameter ROW_ACC = 2;
    parameter OTHER_ROW_START = 3;
    parameter END = 4;
    parameter OUTPUT = 5;
    parameter LOAD = 6;

    reg [DW_ROWIDX-1:0] wkld_end [N_PE-1:0];      // 存储某PE的终止行
    reg [DW_ROWIDX-1:0] row_now [N_PE-1:0];   // 储存某PE现在的行�?
    reg [DW_ELEIDX-1:0] ptr_now [N_PE-1:0]; // 储存某PE现在计算的元素的偏置
    reg [DW_ELEIDX-1:0] ptr_nxr [N_PE-1:0]; // 储存某PE下一行元素的偏置
    reg [DW_ROWIDX-1:0] reg_row_out;
    reg isEmptyRow [N_PE-1:0];

    reg [3:0] state [N_PE-1:0];
    reg [3:0] next_state [N_PE-1:0];
    integer i, j;

    reg [DW_ELEIDX-1:0] row_ptrs [M:0];
    reg [DW_ROWIDX-1:0] row2row [M-1:0];
    reg [DW_ROWIDX-1:0] wlkd_start [N_PE-1:0];

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<N_PE; i=i+1) begin
                wlkd_start[i] <= 0;
            end
            for (i=0; i<=M; i=i+1) begin
                row_ptrs[i] <= 0;
            end
            for (i=0; i<M; i=i+1) begin
                row2row[i] <= 0;
            end
            reg_row_out <= 0;
        end
        else if (write_en) begin
            for (i=0; i<=M; i=i+1) begin
                row_ptrs[i] <= cu_input[i*DW_ELEIDX +:DW_ELEIDX];
            end
            for (i=0; i<M; i=i+1) begin
                row2row[i] <= cu_input[DW_ROWPTR+i*DW_ROWIDX +:DW_ROWIDX];
            end
            for (j=0; j<N_PE; j=j+1) begin
                wlkd_start[j] <= cu_input[DW_ROWPTR+DW_ROW2ROW+j*DW_ROWIDX +:DW_ROWIDX];
                wkld_end[j] <= cu_input[DW_ROWPTR+DW_ROW2ROW+(j+1)*DW_ROWIDX +:DW_ROWIDX];
            end
        end
    end

    always @(posedge clk) begin
        for (i=0; i<N_PE; i=i+1) begin
            if (reset) begin
                wkld_end[i] <= 0;
                row_now[i] <= 0;
                ptr_now[i] <= 0;
                ptr_nxr[i] <= 0;
            end
            else if (state[i] == LOAD) begin
                row_now[i] <= wlkd_start[i];
                ptr_now[i] <= row_ptrs[wlkd_start[i]];
                ptr_nxr[i] <= row_ptrs[wlkd_start[i]+1];
            end
            else if (state[i] == FIRST_ROW_START) begin
                ptr_now[i] <= ptr_now[i] + 1;
                if (ptr_now[i] == ptr_nxr[i] || ptr_now[i] == ptr_nxr[i] - 1) begin
                    row_now[i] <= row_now[i] + 1;
                    ptr_now[i] <= row_ptrs[row_now[i]+1];
                    //ptr_nxr[i] <= row_ptrs[(row_now[i]+2)%M];
                    if (row_now[i]+1 < M) begin
                        ptr_nxr[i] <= row_ptrs[row_now[i]+2];
                    end
                    else begin
                        ptr_nxr[i] <= row_ptrs[row_now[i]+1]+1;
                    end
                end
            end
            else if (state[i] == ROW_ACC) begin
                ptr_now[i] <= ptr_now[i] + 1;
                if (ptr_now[i] == ptr_nxr[i] || ptr_now[i] == ptr_nxr[i] - 1) begin
                    row_now[i] <= row_now[i] + 1;
                    ptr_now[i] <= row_ptrs[row_now[i]+1];
                    //ptr_nxr[i] <= row_ptrs[(row_now[i]+2)%M];
                    if (row_now[i]+1 < M) begin
                        ptr_nxr[i] <= row_ptrs[row_now[i]+2];
                    end
                    else begin
                        ptr_nxr[i] <= row_ptrs[row_now[i]+1]+1;
                    end
                end
            end
            else if (state[i] == OTHER_ROW_START) begin
                ptr_now[i] <= ptr_now[i] + 1;
                if (ptr_now[i] == ptr_nxr[i] || ptr_now[i] == ptr_nxr[i] - 1) begin
                    row_now[i] <= row_now[i] + 1;
                    ptr_now[i] <= row_ptrs[row_now[i]+1];
                    //ptr_nxr[i] <= row_ptrs[(row_now[i]+2)%M];
                    if (row_now[i]+1 < M) begin
                        ptr_nxr[i] <= row_ptrs[row_now[i]+2];
                    end
                    else begin
                        ptr_nxr[i] <= row_ptrs[row_now[i]+1]+1;
                    end
                end
            end
        end
        if (state[0] == OUTPUT && state[1] == OUTPUT && state[2] == OUTPUT && state[3] == OUTPUT) begin
            if (reg_row_out != 4'b1111) begin
                reg_row_out <= reg_row_out + 1;
            end
            else begin
                reg_row_out <= 0;
            end
        end
    end

    always @(posedge clk) begin
        for (i=0; i<N_PE; i=i+1) begin
            state[i] <= next_state[i];
        end
    end

    always @(*) begin
        for (i=0; i<N_PE; i=i+1) begin
            if (reset) begin
                next_state[i] = IDLE;
            end
            else if (state[i]==IDLE) begin
                if (write_en == 0)
                    next_state[i] = IDLE;
                if (write_en == 1)
                    next_state[i] = LOAD;
            end
            else if (state[i] == LOAD) begin
                next_state[i] = FIRST_ROW_START;
            end
            else if (state[i] == FIRST_ROW_START) begin
                if (ptr_now[i] == ptr_nxr[i] || ptr_now[i] == ptr_nxr[i] - 1) begin
                    if ((row_now[i]+1)%M != wkld_end[i]) begin
                        next_state[i] = OTHER_ROW_START;
                    end
                    else begin
                        next_state[i] = END;
                    end
                end
                else begin
                    next_state[i] = ROW_ACC;
                end
            end
            else if (state[i] == ROW_ACC) begin
                if (ptr_now[i] == ptr_nxr[i] || ptr_now[i] == ptr_nxr[i] - 1) begin
                    if ((row_now[i]+1)%M != wkld_end[i]) begin
                        next_state[i] = OTHER_ROW_START;
                    end
                    else begin
                        next_state[i] = END;
                    end
                end
                else begin
                    next_state[i] = ROW_ACC;
                end
            end
            else if (state[i] == OTHER_ROW_START) begin
                if (ptr_now[i] == ptr_nxr[i] || ptr_now[i] == ptr_nxr[i] - 1) begin
                    if ((row_now[i]+1)%M != wkld_end[i]) begin
                        next_state[i] = OTHER_ROW_START;
                    end
                    else begin
                        next_state[i] = END;
                    end
                end
                else begin
                    next_state[i] = ROW_ACC;
                end
            end
            else if (state[i] == END) begin
                next_state[i] = OUTPUT;
            end
        end
        if (state[0] == OUTPUT && state[1] == OUTPUT && state[2] == OUTPUT && state[3] == OUTPUT && reg_row_out == 4'b1111) begin
            next_state[0] = IDLE;
            next_state[1] = IDLE;
            next_state[2] = IDLE;
            next_state[3] = IDLE;
        end
    end

    genvar gi;
    generate
        for (gi=0; gi<N_PE; gi=gi+1) begin
            assign A_ptrs[gi*DW_ELEIDX +:DW_ELEIDX] = ptr_now[gi];
            assign A_rows[gi*DW_ROWIDX +:DW_ROWIDX] = row2row[row_now[gi]];
            assign acc_en[gi] = (state[gi] == FIRST_ROW_START | state[gi] == OTHER_ROW_START) & (ptr_now[gi] != ptr_nxr[gi]);
            assign write_D_en[gi] = (state[gi] == OTHER_ROW_START | state[gi] == END) & !isEmptyRow[gi];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<N_PE; i=i+1) begin
                isEmptyRow[i] <= 0;
            end
        end
        else begin
            for (i=0; i<N_PE; i=i+1) begin
                isEmptyRow[i] <= ptr_now[i] == ptr_nxr[i];
            end
        end
    end

    assign row_out = reg_row_out;
    assign out_valid = (state[0] == OUTPUT && state[1] == OUTPUT && state[2] == OUTPUT && state[3] == OUTPUT);


endmodule