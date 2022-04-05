#!/bin/python3
from sys import stdin, stdout
def rl():
    return list(map(int, stdin.readline().split()))
def ri():
    return int(stdin.readline())
def input():
    return stdin.readline().strip()
def cout(arg):
    if isinstance(arg, list) or isinstance(arg, tuple) or isinstance(arg, set):
        stdout.write(" ".join(list(map(str, arg))))
    else:
        stdout.write(str(arg))
    stdout.write("\n")

