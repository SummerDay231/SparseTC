import os
import sys

def main():
  name = str(sys.argv[1])
  cmd_clear = "rm " + name + ".vcd"
  cmd_compile = "iverilog -o " + name + " -y ../kernel_verilog/src/basic ../kernel_verilog/sim/basic/" + name + ".v"
  cmd_vvp = "vvp -n " + name + " -lxt2"
  cmd_wave = "gtkwave " + name + ".vcd"
  os.system(cmd_clear)
  os.system(cmd_compile)
  os.system(cmd_vvp)
  os.system(cmd_wave)

if __name__ == '__main__':
  main()