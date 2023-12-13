import os
import sys
import pickle
import numpy as np
from collections import OrderedDict
from scipy.sparse import random

'''
  功能：将任意的稀疏矩阵转换为PSB（Primary Sparse Block）格式，输出字典或者numpy格式
  基本设定如下：
    1. 我们以基本块大小为16*16，
  程序的输入和输出：
    1. 输入：任意稀疏矩阵，目前只支持numpy格式
    2. 输出：描述特定稀疏格式的字典文件或者numpy格式
'''

def get_matrix_density(matrix):
  nonzero_count = np.count_nonzero(matrix)
  matrix_size = matrix.size
  density = nonzero_count / matrix_size
  return density

def get_task_density(task):
  nnz = task['m_tile'] * np.sum(np.array(task['block_type'])) * \
        task['k_tile'] / task['k_sub_tile']
  density = nnz / (task['m_iter']*task['k_iter']*task['m_tile']*task['k_tile'])
  return density

class SparseFormat(object):
  m_tile = None
  k_tile = None
  k_sub_tile = None
  Nnz_set = None
  fixed_nnz_pruned = None

  def __init__(self, block_size):
    assert(len(block_size) == 3)
    self.m_tile = block_size[0]
    self.k_tile = block_size[1]
    self.k_sub_tile = block_size[2]
    assert(self.k_tile % self.k_sub_tile == 0)
    self.generate_nnz_set(self.k_sub_tile)
    print('[SparseFormat] m_tile:%d, k_tile:%d'%(self.m_tile, self.k_tile))

  def generate_nnz_set(self, x):
    prun_list = [0,]
    for i in range(1, x+1):
      if x % i == 0:
        prun_list.append(i)
    self.Nnz_set = np.array(prun_list)

  def set_fixed_nnz_pruned(self, x):
    self.fixed_nnz_pruned = int(x)

  def dense2fbs(self, matrix_in):
    m, k = matrix_in.shape
    # OrderedDict to express FlexBlock Format
    matrix_fbs = OrderedDict({'m_size': m, 'k_size': k, \
                              'm_tile': int(self.m_tile), \
                              'k_tile': int(self.k_tile)})
    matrix_fbs['k_sub_tile'] = int(self.k_sub_tile)
    matrix_fbs['m_iter'] = int(np.ceil(m / self.m_tile))
    matrix_fbs['k_iter'] = int(np.ceil(k / self.k_tile))
    matrix_fbs['m_padding'] = m % self.m_tile != 0
    matrix_fbs['k_padding'] = k % self.k_tile != 0
    matrix_fbs['block_type'] = []
    matrix_fbs['block_offset'] = [0,]
    matrix_fbs['element_index'] = []
    matrix_fbs['element_value'] = []

    matrix_dense = np.zeros_like(matrix_in)

    for i in range(matrix_fbs['m_iter']):
      for j in range(matrix_fbs['k_iter']):
        block = self.get_block_matrix(matrix_in, i, j)
        block_type, element_index, element_value, struct_block = self.get_struct_sparse_block(block)

        # 如何处理边界问题？
        matrix_fbs['block_type'].append(block_type)
        if block_type == 0:
          matrix_fbs['block_offset'].append(matrix_fbs['block_offset'][-1])
        else:
          matrix_fbs['block_offset'].append(matrix_fbs['block_offset'][-1] + int(self.m_tile*self.k_tile/block_type))
        matrix_fbs['element_index'].append(element_index)
        matrix_fbs['element_value'].append(element_value)

        # dense output
        self.set_block_matrix(matrix_dense, i, j, struct_block)

    return matrix_fbs, matrix_dense


  def get_block_matrix(self, matrix_in, ptr_m, ptr_k):
    mtx_row, mtx_col = matrix_in.shape
    start_row = ptr_m * self.m_tile
    start_col = ptr_k * self.k_tile
    end_row = min(mtx_row, start_row + self.m_tile)
    end_col = min(mtx_col, start_col + self.k_tile)

    block = matrix_in[start_row:end_row, start_col:end_col]
    block_row, block_col = block.shape
    if (block_row < self.m_tile or block_col < self.k_tile):
      # padding block
      new_block = np.zeros((self.m_tile, self.k_tile))
      new_block[:block.shape[0], :block.shape[1]] = block
      block = new_block
    return block

  def set_block_matrix(self, matrix_in, ptr_m, ptr_k, block_in):
    mtx_row, mtx_col = matrix_in.shape
    start_row = ptr_m * self.m_tile
    start_col = ptr_k * self.k_tile
    size_row = min(mtx_row - start_row, self.m_tile)
    size_col = min(mtx_col - start_col, self.k_tile)
    matrix_in[start_row:start_row+size_row, start_col:start_col+size_col] = block_in[:size_row, :size_col]


  def get_struct_sparse_block(self, block):
    pruned_nnz = None
    sub_block_num = int(self.k_tile/self.k_sub_tile)
    if self.fixed_nnz_pruned == None:
      max_nnz_count = 0
      for sub_block in np.split(block, sub_block_num, axis=1):
        nnz_counts = np.count_nonzero(sub_block, axis=1)
        # todo: other method
        max_nnz_count = max(max_nnz_count, np.max(nnz_counts))
      nnz_list = self.Nnz_set - max_nnz_count
      pruned_nnz = np.where(nnz_list >= 0)[0][0]
    else:
      pruned_nnz = self.fixed_nnz_pruned

    indice_nnz = None
    result_nnz = None
    result_dense = None
    if pruned_nnz == 0 or pruned_nnz == self.Nnz_set[-1]:
      result_dense = block
    else:
      # get the nnz mask
      indice_nnz = np.zeros((block.shape[0], pruned_nnz*sub_block_num), dtype=int)
      for i in range(sub_block_num):
        sub_block = block[:, i*self.k_sub_tile:(i+1)*self.k_sub_tile]
        # 找出每一行中绝对值最大的前两个元素
        abs_matrix = np.abs(sub_block)
        max_indexes = np.argsort(-abs_matrix, axis=1)[:, :pruned_nnz]
        max_indexes = np.sort(max_indexes, axis=1)
        indice_nnz[:, i*pruned_nnz:(i+1)*pruned_nnz] = max_indexes

      # 将绝对值最大的元素置为非零，其余元素置为零
      result_dense = np.zeros_like(block)
      rows = np.arange(block.shape[0]).reshape(-1, 1)
      result_dense[rows, max_indexes] = block[rows, max_indexes]
      # 从原始矩阵中取出对应的元素，并构造一个新的矩阵
      result_nnz = block[np.arange(block.shape[0]).reshape(-1, 1), indice_nnz]

    return pruned_nnz, indice_nnz, result_nnz, result_dense
  


def test():
  m_tile, k_tile = 4, 4
  pruned_nnz = k_tile / 2
  FBS = SparseFormat(m_tile, k_tile)
  FBS.set_fixed_nnz_pruned(pruned_nnz)

  matrix = np.random.randint(-10, 10, size=(6, 11))
  # # 随机生成一个100x100的稀疏矩阵，平均每行有10个非零元素
  # matrix = random(8, 8, density=0.1, format='coo')
  # matrix = matrix.toarray()
  _, matrix_fbs = FBS.dense2fbs(matrix)
  print("原始矩阵为：")
  print(matrix)
  print("转换后的矩阵为：")
  print(matrix_fbs)

def main():
  block = 16
  block_size = (block, block, int(block/2))
  k_tile, m_tile, _ = block_size
  pruned_nnz = k_tile / 2
  FBS = SparseFormat(block_size)
  # FBS.set_fixed_nnz_pruned(pruned_nnz)

  if len(sys.argv) > 1:
    path_in = sys.argv[1]
    flag = f'_{pruned_nnz}:{k_tile}:{m_tile}'
    path_out = os.path.join(path_in, flag)
    matrix_in = np.load(path_in)
    _, matrix_out = FBS.dense2fbs(matrix_in)
    np.save(path_out, matrix_out)
  else:
    # matrix_in = np.random.randint(-10, 10, size=(6, 11))
    matrix = random(1024, 4096, density=0.1, format='coo')
    matrix_in = matrix.toarray()
    task_fbs, matrix_fbs = FBS.dense2fbs(matrix_in)
    print("原始矩阵为：, density=%.2f"%get_matrix_density(matrix_in))
    # print(matrix_in)
    print("转换后的矩阵为：, density=%.2f"%get_task_density(task_fbs))
    # print(matrix_fbs)
    # save task for simulation
    path_task = 'simulator/data.pkl'
    with open(path_task, 'wb') as f:
      pickle.dump(task_fbs, f)
    print('[Save task] in %s'%path_task)


if __name__ == '__main__':
  main()