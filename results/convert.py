#!/bin/env python2

import sys

files = []
ans = []
cost = []
for line in sys.stdin.readlines():
    line_arr = line.split(" ")
    files.append(line_arr[0][:-1])
    ans.append(line_arr[1])
    cost.append(line_arr[4][1:])


def print_row(columns):
    for col in columns:
        sys.stdout.write('|' + col)
    sys.stdout.write('|\n')

print_row(files)
print_row(['---' for i in xrange(len(files))])
print_row(ans)
print_row(cost)
