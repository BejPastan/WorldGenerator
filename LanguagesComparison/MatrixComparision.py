import numpy as np

size = 10000

# generate random matrices of size 10000x10000
def generate_random_matrices():
    return np.random.rand(size, size)

matrix_A = generate_random_matrices()
matrix_B = generate_random_matrices()

# test time of matrix multiplication
import time

start_time = time.time()
result = np.dot(matrix_A, matrix_B)
end_time = time.time()
print(f"{end_time - start_time}")