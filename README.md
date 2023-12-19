# README

1. 新建工程，添加./kernel_verilog下代码
2. 按照实际目录修改./test/tile_run.py 和 ./kernel_verilog/sim/unstructured/tb_stc_core_auto.sv中的文件地址信息
3. 运行tile_run.py，此时会出现提示"Please run verilog simulation."
4. 运行tb_stc_core_auto.sv
5. 回到python命令行，输入任意键继续
6. 显示测试结果

## 代码层级
- stc_core
  - stc_cu
  - stc_ABuffer
  - stc_BBuffer
  - stc_A_DN
  - stc_B_DN
    - stc_crossbar
  - stc_pe_array
  - stc_accumulator
  - stc_DBuffer

- CU(Control Unit)
  - 控制信号的来源，以及存放着row idx这一列的信息，用以控制
- A_buffer
  - 存放A，给定idx，输出数据
- B_buffer
  - 存放B，给定idx，输出数据
- A_DN
  - 把A复制16份，从4*1变成4*16
- B_DN
  - B的输入是16*16，通过一个16to4的crossbar，变成4*16
- PE_Array
  - 接收64个a和b，输出64个c
- Accumulator
  - 四个加法器阵列，每个处理一行16个数，一行累加完成时把结果输出给C_buffer
- D_buffer
  - 存放C，给定idx，写入/输出对应行