import os
import numpy as np

class TileSimulator(object):
    def __init__(self) -> None:
        self.file_dir = "C:/Project/SparseTensorCore/sparse-tensor-core/test/"
        self.m = 16
        self.n = 16
        self.k = 16
        self.N_PE = 4
        self.sparsity = 0.2
        self.upper_bound = 127

    def genSpMat(self, m, k, upper_bound=127):
        spmat = np.random.rand(m, k)
        spmat = (spmat < self.sparsity).astype(int)
        nnz = spmat.sum()
        spmat = spmat * np.random.randint(1,upper_bound, (m, k))
        return spmat, nnz

    def genDenMat(self, m, n, upper_bound=127):
        return np.random.randint(0,127, (m, n))

    def workload_balance(self, a):
        row_nnz = (a!=0).sum(axis=1)
        PE_wkld = np.array([0, 0, 0, 0])
        PE_rows = []
        for i in range(self.N_PE):
            PE_rows.append([])
        for i in np.argsort(row_nnz)[::-1]:
            minPE = PE_wkld.argmin()
            PE_wkld[minPE] += row_nnz[i]
            PE_rows[minPE].append(i)
        row2row = []
        row2row_reverse = [0]*16
        wkld_ptrs = [0]
        for i in PE_rows:
            wkld_ptrs.append(wkld_ptrs[-1]+len(i))
            row2row += i
        row2row_reverse = np.argsort(row2row)
        wkld_ptrs[-1] = 0
        return row2row, row2row_reverse, wkld_ptrs

    def write_a(self, a, nnz):
        m, k = a.shape
        row2row, row2row_reverse, wkld_ptrs = self.workload_balance(a)
        sorted_a = a[row2row,:]
        a_data = []
        a_col = []
        row_ptr = []
        ptr = 0
        for i in range(m):
            row_ptr.append(ptr)
            for j in range(k):
                if sorted_a[i,j] != 0:
                    a_data.append(sorted_a[i, j])
                    a_col.append(j)
                    ptr += 1
        row_ptr.append(ptr)
        with open(self.file_dir + "Abuf.txt", 'w') as f:
            for i in range(nnz):
                f.write('{:04x} '.format(a_data[i]))
        with open(self.file_dir + "Acol.txt", 'w') as f:
            for i in range(nnz):
                f.write('{:04x} '.format(a_col[i]))
        with open(self.file_dir + "ctrl_info.txt", 'w') as f:
            for i in range(m+1):
                f.write('{:04x} '.format(row_ptr[i]))
            for i in range(m):
                f.write('{:04x} '.format(row2row[i]))
            for i in wkld_ptrs:
                f.write('{:04x} '.format(i))
            f.write('{:04x} '.format(0))
            f.write('{:04x} '.format(int(np.ceil(nnz/16))))
    
    def write_b(self, b):
        with open(self.file_dir  +"Bbuf.txt", 'w') as f:
            lines = []
            for i in b:
                line = ""
                for j in i:
                    line += '{:04x} '.format(j)
                line += '\n'
                lines.append(line)
            f.writelines(lines)

    def write_c(self, c):
        with open(self.file_dir + "Cbuf.txt", 'w') as f:
            lines = []
            for i in c:
                line = ""
                for j in i:
                    line += '{:04x} '.format(j)
                line += '\n'
                lines.append(line)
            f.writelines(lines)

    def read_d(self):
        with open(self.file_dir + "Dbuf.txt", 'r') as f:
            d_str = f.read()
        d = d_str.split()
        d = np.array([int(i) for i in d]).reshape((self.m, self.n))
        return d
    
    def check(self):
        return (np.matmul(self.A, self.B) + self.C == self.D).sum() == self.m*self.n
    
    def run(self):
        self.A, self.nnz = self.genSpMat(self.m, self.k)
        self.B = self.genDenMat(self.k, self.n)
        self.C = self.genDenMat(self.m, self.n)
        self.write_a(self.A, self.nnz)
        self.write_b(self.B)
        self.write_c(self.C)
        print("Please run verilog simluation.")
        os.system("pause")
        self.D = self.read_d()
        if (self.check()):
            print("Result correct.")
        else:
            print("Wrong result!")

if __name__ == "__main__":
    sim = TileSimulator()
    sim.run()