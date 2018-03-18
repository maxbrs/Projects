import multiprocessing as mp

def cube(x):
    return x**3

if __name__ == "__main__":
    pool = mp.Pool(processes = mp.cpu_count())
    results = pool.map(cube, [1, 2, 3])
    print("Number of cpu : ", mp.cpu_count())
    print(results)
