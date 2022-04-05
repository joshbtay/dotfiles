#!/bin/python3
import os
class colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
home = os.path.expanduser("~") +"/"

#copy all files
os.system("rsync -av --exclude '.git/' --exclude 'install.py' --exclude 'append_bashrc' . ~/")

#bashrc additions
bashrc = open(home + ".bashrc")
append_bashrc = open("append_bashrc")
bashrc = bashrc.read()
append_bashrc = [line.rstrip() for line in append_bashrc.readlines()]
for line in append_bashrc:
    if len(line) > 8: break
if line not in bashrc:
    print(f"{colors.GREEN}Adding append_bashrc to ~/.bashrc{colors.ENDC}")
    bashrc = open(home + ".bashrc", "a")
    if not append_bashrc[0]: bashrc.write("\n")
    for line in append_bashrc:
        bashrc.write(line)
        bashrc.write("\n")
else:
    print(f"{colors.WARNING}Skipping append_bashrc{colors.ENDC}")
