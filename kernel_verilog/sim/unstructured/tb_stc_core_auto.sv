`timescale 1ns / 1ps

module tb_stc_core_auto();

parameter M = 16;
parameter K = 16;
parameter N = 16;
parameter N_PE = 4;
parameter DW_MEM = 256;
parameter DW_DATA = 16;
parameter DW_IDX = 4;
parameter DW_PTR = 8;
parameter DW_ROWPTR = (M+1)*DW_PTR;
parameter DW_ROW2ROW = M*DW_IDX;
//string FILE_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured";
//parameter Abuf_DIR = $sformatf("%s/Abuf.txt",FILE_DIR);
parameter Abuf_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/test/Abuf.txt";
parameter Acol_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/test/Acol.txt";
parameter ctrl_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/test/ctrl_info.txt";
parameter Bbuf_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/test/Bbuf.txt";
parameter Cbuf_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/test/Cbuf.txt";
parameter Dbuf_DIR = "C:/Project/SparseTensorCore/sparse-tensor-core/test/Dbuf.txt";

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
reg [DW_DATA-1:0] Amemory [0:255];
reg [DW_DATA-1:0] Acol [0:255];
reg [DW_DATA-1:0] Bmemory [0:255];
reg [DW_DATA-1:0] Cmemory [0:255];
reg [DW_DATA-1:0] ctrl_info [0:255];
reg [DW_DATA-1:0] Dmemory [0:255];
integer i, j, row_out, file_handle;
integer nnz = 24;

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
    for (i=0; i<255; i=i+1) begin
        Amemory[i] = 0;
        Acol[i] = 0;
    end
    $readmemh(Abuf_DIR, Amemory);
    // $readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/unstructured/Abuf.txt", Amemory);
    $readmemh(Acol_DIR, Acol);
    $readmemh(ctrl_DIR, ctrl_info);
	$readmemh(Bbuf_DIR, Bmemory);
	$readmemh(Cbuf_DIR, Cmemory);
	#10
    reset = 0;
    write_a_data_en = 1;
    write_a_cidx_en = 1;
    // for (i=0; i<4; i=i+1) begin
    for (i=0; i<ctrl_info[2*M+7]; i=i+1) begin
        A_idx = i;
        for (j=0; j<16; j=j+1) begin
            A_data_input[j*DW_DATA +:DW_DATA] = Amemory[i*16+j];
            A_colidx_input[j*DW_IDX +:DW_IDX] = Acol[i*16+j];
        end
        #10;
    end
    write_a_data_en = 0;
    write_a_cidx_en = 0;
    write_b = 1;
    write_c = 1;
    for (i=0; i<M; i=i+1) begin
        B_row = i;
        in_c_row = i;
        for (j=0; j<K; j=j+1) begin
            B_input[j*DW_DATA +:DW_DATA] = Bmemory[i*M+j];
            in_c[j*DW_DATA +:DW_DATA] = Cmemory[i*M+j];
        end
        #10;
    end
    write_b = 0;
    write_c = 0;
    write_cu = 1;
    for (i=0; i<=M; i=i+1) begin
        cu_input[i*DW_PTR +:DW_PTR] = ctrl_info[i];
    end
    for (i=0; i<M; i=i+1) begin
        cu_input[DW_ROWPTR+i*DW_IDX +:DW_IDX] = ctrl_info[M+1+i];
    end
    for (i=0; i<5; i=i+1) begin
        cu_input[DW_ROWPTR+DW_ROW2ROW+i*DW_IDX +:DW_IDX] = ctrl_info[2*M+1+i];
    end
    #10;
    write_cu = 0;
    #700
    file_handle = $fopen(Dbuf_DIR, "w");
    for (i=0; i<M*N; i=i+1) begin
        $fwrite(file_handle, "%d ", Dmemory[i]);
    end
    $fclose(file_handle);
    //$display(Abuf_DIR);
    $finish;
end

always @(posedge clk) begin
    if (out_valid) begin
        for (i=0; i<N; i=i+1) begin
            Dmemory[row_out*N+i] <= out_d[i*DW_DATA +:DW_DATA];
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