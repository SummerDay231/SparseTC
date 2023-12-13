`timescale 1ns / 1ps

module tb_stc_core();

parameter M = 16;
parameter K = 16;
parameter N = 16;
parameter N_PE = 4;
parameter DW_MEM = 256;
parameter DW_DATA = 16;
parameter DW_IDX = 4;
parameter DW_PTR = 8;

reg clk;
reg reset;
// cu input
reg write_cu;
reg [DW_MEM-1:0] cu_input;
// a input
reg write_a_data_en;
reg write_a_cidx_en;
reg [DW_MEM-1:0] A_data_input;
reg [DW_MEM-1:0] A_colidx_input;
reg [DW_IDX-1:0] A_idx;
// b input
reg write_b;
reg [DW_MEM-1:0] B_input;
reg [DW_IDX-1:0] B_row;
// c input
reg write_c;
reg [N*DW_DATA-1:0] in_c;
reg [DW_IDX-1:0] in_c_row;
// output
wire out_valid;
wire [N*DW_DATA-1:0] out_d;

always #5 clk = ~clk;
// reg [15:0] Amemory [0:255];
reg [15:0] Bmemory [0:255];
reg [15:0] Cmemory [0:255];
integer i, j, row_out, file_handle;

initial begin
    clk = 1;
    reset = 1;
    write_cu = 0;
    cu_input = 0;
    write_a_data_en = 0;
    write_a_cidx_en = 0;
    A_data_input = 0;
    A_colidx_input = 0;
    A_idx = 0;
    write_b = 0;
    B_input = 0;
    B_row = 0;
    write_c = 0;
    in_c = 0;
    in_c_row = 0;
    row_out = 0;
    //$readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Abuf.txt", Amemory);
	$readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Bbuf0.txt", Bmemory);
	#10
    reset = 0;
    write_a_data_en = 1;
    write_a_cidx_en = 1;
    A_data_input = {16'd15, 16'd14, 16'd13, 16'd12, 16'd11, 16'd10, 16'd9, 16'd8, 
                    16'd7, 16'd6, 16'd5, 16'd4, 16'd3, 16'd2, 16'd1, 16'd0};
    A_colidx_input = {4'd12, 4'd6, 4'd5, 4'd12, 4'd6, 4'd5, 4'd4, 4'd15, 
                      4'd14, 4'd11, 4'd10, 4'd9, 4'd7, 4'd4, 4'd2, 4'd0};
    A_idx = 0;
    #10
    A_data_input = {16'd31, 16'd30, 16'd29, 16'd28, 16'd27, 16'd26, 16'd25, 16'd24, 
                    16'd23, 16'd22, 16'd21, 16'd20, 16'd19, 16'd18, 16'd17, 16'd16};
    A_colidx_input = {4'd7, 4'd13, 4'd11, 4'd9, 4'd6, 4'd3, 4'd1, 4'd13, 
                      4'd11, 4'd9, 4'd8, 4'd5, 4'd4, 4'd2, 4'd1, 4'd7};
    A_idx = 1;
    #10
    A_data_input = {16'd47, 16'd46, 16'd45, 16'd44, 16'd43, 16'd42, 16'd41, 16'd40, 
                    16'd39, 16'd38, 16'd37, 16'd36, 16'd35, 16'd34, 16'd33, 16'd32};
    A_colidx_input = {4'd11, 4'd8, 4'd5, 4'd2, 4'd12, 4'd10, 4'd7, 4'd4, 
                      4'd1, 4'd13, 4'd11, 4'd9, 4'd6, 4'd3, 4'd0, 4'd8};
    A_idx = 2;
    #10
    A_data_input = {16'd63, 16'd62, 16'd61, 16'd60, 16'd59, 16'd58, 16'd57, 16'd56, 
                    16'd55, 16'd54, 16'd53, 16'd52, 16'd51, 16'd50, 16'd49, 16'd48};
    A_colidx_input = {4'd11, 4'd8, 4'd3, 4'd13, 4'd5, 4'd2, 4'd11, 4'd7, 
                      4'd6, 4'd3, 4'd14, 4'd9, 4'd5, 4'd2, 4'd0, 4'd15};
    A_idx = 3;
    #10
    write_a_data_en = 0;
    write_a_cidx_en = 0;
    write_b = 1;
    write_c = 1;
    for (i=0; i<M; i=i+1) begin
        B_row = i;
        in_c_row = i;
        for (j=0; j<K; j=j+1) begin
            B_input[j*DW_DATA +:DW_DATA] = Bmemory[i*M+j];
            in_c[j*DW_DATA +:DW_DATA] = Bmemory[i*M+j];
        end
        #10;
    end
    write_b = 0;
    write_c = 0;
    write_cu = 1;
    cu_input = {4'd0, 4'd12, 4'd8, 4'd5, 4'd0,
                4'd15, 4'd14, 4'd13, 4'd12, 4'd11, 4'd10, 4'd9, 4'd8,
                4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0,
                8'd64, 8'd61, 8'd58, 8'd54, 8'd49, 8'd48, 8'd44, 8'd39, 8'd33,
                8'd31, 8'd25, 8'd17, 8'd16, 8'd16, 8'd13, 8'd9, 8'd0};
    #10
    write_cu = 0;
    #400
    file_handle = $fopen("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Dbuf0.txt", "w");
    for (i=0; i<M*N; i=i+1) begin
        $fwrite(file_handle, "%d ", Cmemory[i]);
    end
    $fclose(file_handle);
    $finish;
end

always @(posedge clk) begin
    if (out_valid) begin
        for (i=0; i<N; i=i+1) begin
            Cmemory[row_out*N+i] <= out_d[i*DW_DATA +:DW_DATA];
        end
        row_out <= row_out + 1;
    end
end

stc_core #(
    .M(M),
    .K(K),
    .N(N),
    .N_PE(N_PE),
    .DW_MEM(DW_MEM),
    .DW_DATA(DW_DATA),
    .DW_IDX(DW_IDX),
    .DW_PTR(DW_PTR)
) u_core(
    .clk(clk),
    .reset(reset),
    .write_cu(write_cu),
    .cu_input(cu_input),
    .write_a_data_en(write_a_data_en),
    .write_a_cidx_en(write_a_cidx_en),
    .A_data_input(A_data_input),
    .A_colidx_input(A_colidx_input),
    .A_idx(A_idx),
    .write_b(write_b),
    .B_input(B_input),
    .B_row(B_row),
    .write_c(write_c),
    .in_c(in_c),
    .in_c_row(in_c_row),
    .out_valid(out_valid),
    .out_d(out_d)
);

endmodule