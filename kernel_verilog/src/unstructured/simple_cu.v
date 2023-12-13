`timescale 1ns / 1ps

module simple_cu #(
    parameter M = 16,
    parameter DW_MEM = 512,
    parameter DW_ROWIDX = 4,
    parameter DW_ELEIDX = 8,
    parameter N_PE = 1,
    parameter DW_DATA = 8,
    parameter DW_ROWPTR = (M+1)*DW_ELEIDX,
    parameter DW_ROW2ROW = M*DW_ROWIDX,
    parameter DW_WKLDPTR = N_PE*DW_ROWIDX
) (
    input clk,
    input reset,
    input write_en,
    input [DW_MEM-1:0] cu_input,
    output [DW_ELEIDX-1:0] A_ptr,
    output acc_en,
    output [DW_ROWIDX-1:0] A_row,
    output out_valid,
    output [DW_ROWIDX-1:0] row
);

    parameter IDLE = 0;
    parameter FIRST_ROW_START = 1;
    parameter ROW_ACC = 2;
    parameter OTHER_ROW_START = 3;
    parameter END = 4;
    parameter OUTPUT = 5;
    parameter LOAD = 6;

    reg [DW_ROWIDX-1:0] wkld_end;      // 存储某PE的终止行
    reg [DW_ROWIDX-1:0] row_now;   // 储存某PE现在的行�?
    reg [DW_ELEIDX-1:0] ptr_now; // 储存某PE现在计算的元素的偏置
    reg [DW_ELEIDX-1:0] ptr_nxr; // 储存某PE下一行元素的偏置

    reg [3:0] state;
    reg [3:0] next_state;
    integer i;

    reg [DW_ELEIDX-1:0] row_ptrs [M:0];
    reg [DW_ROWIDX-1:0] row2row [M-1:0];
    reg [DW_ROWIDX-1:0] wlkd_start;

    always @(posedge clk) begin
        if (reset) begin
            wlkd_start <= 0;
            for (i=0; i<=M; i=i+1) begin
                row_ptrs[i] <= 0;
            end
            for (i=0; i<M; i=i+1) begin
                row2row[i] <= 0;
            end
        end
        else if (write_en) begin
            for (i=0; i<=M; i=i+1) begin
                row_ptrs[i] <= cu_input[i*DW_ELEIDX +:DW_ELEIDX];
            end
            for (i=0; i<M; i=i+1) begin
                row2row[i] <= cu_input[DW_ROWPTR+i*DW_ROWIDX +:DW_ROWIDX];
            end
            wlkd_start <= cu_input[DW_ROWPTR+DW_ROW2ROW +:DW_ROWIDX];
            wkld_end <= cu_input[DW_ROWPTR+DW_ROW2ROW+DW_ROWIDX +:DW_ROWIDX];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            wkld_end <= 0;
            row_now <= 0;
            ptr_now <= 0;
            ptr_nxr <= 0;
        end
        else if (state == LOAD) begin
            row_now <= wlkd_start;
            ptr_now <= row_ptrs[row_now];
            ptr_nxr <= row_ptrs[row_now+1];
        end
        else if (state == FIRST_ROW_START) begin
            ptr_now <= ptr_now + 1;
            if (ptr_now == ptr_nxr || ptr_now == ptr_nxr - 1) begin
                row_now <= row_now + 1;
                ptr_now <= row_ptrs[row_now+1];
                ptr_nxr <= row_ptrs[row_now+2];
            end
        end
        else if (state == ROW_ACC) begin
            ptr_now <= ptr_now + 1;
            if (ptr_now == ptr_nxr || ptr_now == ptr_nxr - 1) begin
                row_now <= row_now + 1;
                ptr_now <= row_ptrs[row_now+1];
                ptr_nxr <= row_ptrs[row_now+2];
            end
        end
        else if (state == OTHER_ROW_START) begin
            ptr_now <= ptr_now + 1;
            if (ptr_now == ptr_nxr || ptr_now == ptr_nxr - 1) begin
                row_now <= row_now + 1;
                ptr_now <= row_ptrs[row_now+1];
                ptr_nxr <= row_ptrs[row_now+2];
            end
        end
    end

    always @(posedge clk) begin
        state <= next_state;
    end

    always @(*) begin
        if (reset) begin
            next_state = IDLE;
        end
        else if (state==IDLE) begin
            if (write_en == 0)
                next_state = IDLE;
            if (write_en == 1)
                next_state = LOAD;
        end
        else if (state == LOAD) begin
            next_state = FIRST_ROW_START;
        end
        else if (state == FIRST_ROW_START) begin
            next_state = ROW_ACC;
        end
        else if (state == ROW_ACC) begin
            if (ptr_now == ptr_nxr || ptr_now == ptr_nxr - 1) begin
                if (row_now != wkld_end-1) begin
                    next_state = OTHER_ROW_START;
                end
                else begin
                    next_state = END;
                end
            end
            else begin
                next_state = ROW_ACC;
            end
        end
        else if (state == OTHER_ROW_START) begin
            if (ptr_now == ptr_nxr || ptr_now == ptr_nxr - 1) begin
                if (row_now != wkld_end-1) begin
                    next_state = OTHER_ROW_START;
                end
                else begin
                    next_state = END;
                end
            end
            else begin
                next_state = ROW_ACC;
            end
        end
    end

    assign A_ptr = ptr_now;
    assign A_row = row_now;
    assign acc_en = (state == FIRST_ROW_START | state == OTHER_ROW_START) & (ptr_now != ptr_nxr);


endmodule