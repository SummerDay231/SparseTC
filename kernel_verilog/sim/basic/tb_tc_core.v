`timescale 1ns / 1ps

module tb_tc_core();

parameter M = 16;
parameter N = 16;
parameter K = 16;
parameter TILE_M = 4;
parameter TILE_N = 4;
parameter TILE_K = 4;
parameter TILE_SIZE = 16;
parameter NUM_TILE = 16;
parameter N_PE = 4;
parameter N_UNIT = 64;
parameter DW_DATA = 16;
parameter DW_IDX = 4;
parameter DW_MEM = 256;

reg clk;
reg reset;
// control signal
reg load_en;
reg compute_en;
// A reg
reg write_a;
reg [DW_MEM-1:0] A_input;
reg [DW_IDX-1:0] A_row;
// B reg
reg write_b;
reg [DW_MEM-1:0] B_input;
reg [DW_IDX-1:0] B_row;
// C reg
reg write_c;
reg [DW_MEM-1:0] C_input;
reg [DW_IDX-1:0] C_row;
// D wire
wire out_valid;
wire [DW_MEM-1:0] D_row_out;

always #5 clk = ~clk;
reg [15:0] Amemory [0:255];
reg [15:0] Bmemory [0:255];
reg [15:0] Cmemory [0:255];
integer i, j, row_out, file_handle;

initial begin
    clk = 1;
    reset = 1;
	$readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/basic/Abuf.txt", Amemory);
	$readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/basic/Bbuf.txt", Bmemory);
	$readmemh("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/basic/Cbuf.txt", Cmemory);
    load_en = 0;
    compute_en = 0;
    write_a = 0;
    A_input = 0;
    A_row = 0;
    write_b = 0;
    B_input = 0;
    B_row = 0;
    write_c = 0;
    C_input = 0;
    C_row = 0;
    row_out = 0;
    file_handle = 0;
    #10
    reset = 0;
    load_en = 1;
    write_a = 1;
    write_b = 1;
    write_c = 1;
    for (i=0; i<M; i=i+1) begin
        A_row = i;
        B_row = i;
        C_row = i;
        for (j=0; j<K; j=j+1) begin
            A_input[j*DW_DATA +:DW_DATA] = Amemory[i*M+j];
            B_input[j*DW_DATA +:DW_DATA] = Bmemory[i*M+j];
            C_input[j*DW_DATA +:DW_DATA] = Cmemory[i*M+j];
        end
        #10;
    end
    load_en = 0;
    write_a = 0;
    write_b = 0;
    write_c = 0;
    compute_en = 1;
    #10
    compute_en = 0;
    #800
    file_handle = $fopen("C:/Project/SparseTensorCore/sparse-tensor-core/kernel_verilog/sim/basic/Dbuf.txt", "w");
    for (i=0; i<M*N; i=i+1) begin
        $fwrite(file_handle, "%d ", Cmemory[i]);
    end
    $fclose(file_handle);
    $finish;
end

always @(posedge clk) begin
    if (out_valid) begin
        for (i=0; i<N; i=i+1) begin
            Cmemory[row_out*N+i] <= D_row_out[i*DW_DATA +:DW_DATA];
        end
        row_out <= row_out + 1;
    end
end

tc_core #(
    .DW_DATA(DW_DATA),
    .DW_MEM(DW_MEM)
)u_tc_core (
    .clk(clk),
    .reset(reset),
    .load_en(load_en),
    .compute_en(compute_en),
    .write_a(write_a),
    .A_input(A_input),
    .A_row(A_row),
    .write_b(write_b),
    .B_input(B_input),
    .B_row(B_row),
    .write_c(write_c),
    .C_input(C_input),
    .C_row(C_row),
    .out_valid(out_valid),
    .D_row_out(D_row_out)
);

endmodule