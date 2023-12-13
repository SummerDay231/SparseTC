import os
import numpy as np
from collections import OrderedDict
import pickle
import random

import fbs_format as FBS

'''
  对Taylor Tensor Core抽象，仿真执行时间
  基本设定如下：
    1. 我们以块block作为基本计算粒度，当然不同block所需要的执行周期数也不尽相同
    2. 硬件的并行度为mkn=484，基本块大小为16*16，目前版本不支持参数化
    3. 关于仿真建模：只考虑计算和写回的周期数，认为读取矩阵可以被计算掩盖，认为流水线方式执行
  程序的输入和输出：
    1. 输入：描述特定稀疏格式的字典文件
    2. 输出：硬件执行的周期数，以及相比稠密方式的加速
'''


class TaylorTensorCore(object):
  # ------- hardware -------
  NumPU = 4
  NumPE = 4
  NumMultiplier = 8
  # Bytes, input is FP16, output is FP32
  BW_read_memory_bytes = 128
  BW_write_memory_bytes = 128
  sizeof_invalue = 2
  sizeof_outvalue = 4
  # ------- basic block -------
  block_size = (16, 16)


  def runComputation(self, nnz_per_row):
    cycle = None
    if nnz_per_row == 0:
      cycle = 0
    else:
      cycle = int((self.block_size[0] * nnz_per_row) / (self.NumPU * self.NumMultiplier))
    return cycle

  def runWriteMatrix(self, task_m_slice, task_n_size):
    psum_buffer_size = task_m_slice * task_n_size * self.sizeof_outvalue
    cycle = int(psum_buffer_size / self.BW_write_memory_bytes)
    return cycle

  def getsparsity(self, task):
    assert(task['k_tile'] == self.block_size[1])
    nnz = 0
    for i in range(task['m_iter']*task['k_iter']):
      nnz += task['m_tile'] * task['block_type'][i]
    sparsity = 1 - nnz / (task['m_iter']*task['k_iter']*task['m_tile']*task['k_tile'])
    return sparsity

  def runTaylorTC(self, task):
    # test
    assert(task['m_tile'] == self.block_size[0])
    assert(task['k_tile'] == self.block_size[1])

    m_iter = task['m_iter']
    k_iter = task['k_iter']
    n_iter = int(np.ceil(task['n_size'] / self.NumPE))
    n_size = task['n_size']

    total_cycle = 0
    total_cycle_computation = 0
    total_cycle_write_psum = 0

    cycle_write_psum = self.runWriteMatrix(self.block_size[0], n_size)
    for ptr_m in range(m_iter):
      cycle_computation = 0
      for ptr_k in range(k_iter):
        nnz_per_row = task['k_tile'] / task['k_sub_tile'] * \
                      task['block_type'][ptr_m*k_iter+ptr_k]
        cycle_computation += self.runComputation(nnz_per_row) * n_iter
      total_cycle_computation += cycle_computation
      if ptr_m == 0:
        total_cycle += cycle_computation
      else:
        total_cycle += max(cycle_computation, cycle_write_psum)
    total_cycle_write_psum += cycle_write_psum * m_iter
    total_cycle += cycle_write_psum

    return total_cycle, total_cycle_computation, total_cycle_write_psum

  def runDenseTC(self, task):
    m_iter = int(np.ceil(task['m_size'] / self.NumPU))
    k_iter = int(np.ceil(task['k_size'] / self.NumMultiplier))
    n_iter = int(np.ceil(task['n_size'] / self.NumPE))
    n_size = task['n_size']

    cycle_computation = k_iter * n_iter
    cycle_write_psum = self.runWriteMatrix(self.NumPU, n_size)
    total_cycle_computation = cycle_computation * m_iter
    total_cycle_write_psum = cycle_write_psum * m_iter
    total_cycle = m_iter * max(cycle_computation, cycle_write_psum) + cycle_write_psum

    return total_cycle, total_cycle_computation, total_cycle_write_psum

def DataLoaderCNN():
  name = '256_128_3_3'
  task_block_size = (16, 16, 16)
  path_file = 'datasets/ICCAD23_FBS'
  path_matrix = os.path.join(path_file, 'weight_' + name + '.npy')
  path_block_type = os.path.join(path_file, 'sp_opt_' + name + '.npy')
  
  matrix = np.load(path_matrix)
  block_type = np.load(path_block_type)
  assert(matrix.size <= block_type.size*task_block_size[0]*task_block_size[1])
  print('[DataLoaderCNN] matrix size: ', matrix.shape)

  task = OrderedDict({'m_size': matrix.shape[0], 'k_size': matrix.shape[1], 'm_tile': task_block_size[0], 'k_tile': task_block_size[1]})
  task['k_sub_tile'] = task_block_size[2]
  task['m_iter'] = int(np.ceil(task['m_size'] / task['m_tile']))
  task['k_iter'] = int(np.ceil(task['k_size'] / task['k_tile']))
  task['block_type'] = list(2 * block_type.astype(np.int32).flatten())
  mtx_density = FBS.get_matrix_density(matrix)
  task_density = FBS.get_task_density(task)
  print('Matrix density: %.2f, Task density: %.2f, up: %.1f'\
        %(mtx_density, task_density, task_density/mtx_density))
    
  return task

def DataLoaderGNN():
  name = 'cora_A'
  task_block_size = (16, 16, 8)
  path_file = 'datasets/GNN'
  path_matrix = os.path.join(path_file, name + '.npy')
  
  matrix = np.load(path_matrix)
  print('[DataLoaderGNN] matrix size: ', matrix.shape)
  
  fbs_transfer = FBS.SparseFormat(task_block_size)
  task, _ = fbs_transfer.dense2fbs(matrix)
  mtx_density = FBS.get_matrix_density(matrix)
  task_density = FBS.get_task_density(task)
  print('Matrix density: %.2f, Task density: %.2f, up: %.1f'\
        %(mtx_density, task_density, task_density/mtx_density))
  return task


def test_demo(task=None):
  if task == None:
    task_size = (300, 300)
    task_block_size = (16, 16)
    task = OrderedDict({'m_size': task_size[0], 'k_size': task_size[1], 'm_tile': task_block_size[0], 'k_tile': task_block_size[1]})
    task['m_iter'] = int(np.ceil(task_size[0] / task_block_size[0]))
    task['k_iter'] = int(np.ceil(task_size[1] / task_block_size[1]))
    task['block_type'] = []
    for i in range(task['m_iter']*task['k_iter']):
      value = random.choice([0, 1, 2, 4, 8])
      task['block_type'].append(value)
  # add infomation
  task['n_size'] = 128
  
  # instantiate TTC
  TTC = TaylorTensorCore()
  ttc_cycle, ttc_cycle_calc, ttc_cycle_write = TTC.runTaylorTC(task)
  # print('[Check sparsity] sparsity: %.2f'%TTC.getsparsity(task))
  print('[TTC] total cycle: %d, computation: %.2f, memory(write): %.2f'%(ttc_cycle, ttc_cycle_calc / ttc_cycle, ttc_cycle_write / ttc_cycle))
  dtc_cycle, dtc_cycle_calc, dtc_cycle_write = TTC.runDenseTC(task)
  print('[DTC] total cycle: %d, computation: %.2f, memory(write): %.2f'%(dtc_cycle, dtc_cycle_calc / dtc_cycle, dtc_cycle_write / dtc_cycle))
  print('Speed up: %.1f'%(dtc_cycle / ttc_cycle))

def main():
  # load task for simulation
  # path_task = 'simulator/data.pkl'
  # with open(path_task, 'rb') as f:
  #   task = pickle.load(f)
  # print('[Load task] from %s'%path_task)
  
  # load task for datasets: CNN
  task = DataLoaderCNN()
  
  # load task for datasets: GNN
  # task = DataLoaderGNN()
  
  test_demo(task)
  

if __name__ == '__main__':
  # test_demo()
  main()
  # DataLoaderCNN()