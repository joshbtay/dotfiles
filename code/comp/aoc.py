from collections import *
from heapq import *
from bisect import *
from math import *
from sys import stdin
def rl(f=int):
    return list(map(f, input().split()))
def rn(f=int):
    return f(input())
def rls():
    return [line.strip() for line in stdin.readlines()]
def pj(line):
    print(''.join(map(str, line)))
mx=my=-inf
Mx=My=inf
for line in stdin:
    line = line.strip()

