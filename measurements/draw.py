#!/usr/bin/env python2

import matplotlib.pyplot as plt

def main(input_file):
    fin = open(input_file, 'r')
    ts_arr = []
    tx_arr = []
    x = []
    y = []
    i = 0
    line = fin.readline()
    ts, tx = map(int, line.strip().split(' '))
    ts_arr.append(ts)
    tx_arr.append(tx)
    lines = fin.readlines();
    for ii in range(10, len(lines), 1):
        line = lines[ii]
        ts, tx = map(int, line.strip().split(' '))
        ts_arr.append(ts)
        tx_arr.append(tx)
        x.append((ts - ts_arr[0]) / 1e6)
        y.append(1e9 * (tx - tx_arr[i]) / (ts - ts_arr[i]))
        i += 1
        if i > 50000:
            break
    plt.figure()
    plt.plot(x[:], y[:])
    plt.savefig(input_file[:input_file.index('_')] + '.png')

if __name__ == '__main__':
	main('/tmp/rcv_data')
	main('/tmp/xmit_data')
