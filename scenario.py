#!/usr/bin/env python3
# This script typically needs to be run as root.
# Usage: sudo scenario.py `pgrep dosbox`

import subprocess
import sys

process_id = sys.argv[1]

RED = 0
YELLOW = 1
ORANGE = 2
GREEN = 3
PINK = 4
BLUE = 5

BASE_ADDRESS = 0x7fffd8010ff6

X_COORDS_ADDRESS = BASE_ADDRESS
Y_COORDS_ADDRESS = BASE_ADDRESS + 24
DIRECTIONS_ADDRESS = BASE_ADDRESS + 48

scanmem_command = f"option endianness 1;write float32 {hex(BASE_ADDRESS)} 450;exit"

subprocess.run([ "scanmem", process_id, "--errexit", "--command", scanmem_command ])
