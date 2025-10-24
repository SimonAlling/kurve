#!/usr/bin/env python3
# This script typically needs to be run as root.
# Usage: sudo ./scenario.py `pgrep dosbox`

import math
import subprocess
import sys

process_id = sys.argv[1]

RED = 0
YELLOW = 1
ORANGE = 2
GREEN = 3
PINK = 4
BLUE = 5

SIZEOF_FLOAT = 4

BASE_ADDRESS = 0x7fffd8010ff6

X_COORDS_ADDRESS = BASE_ADDRESS
Y_COORDS_ADDRESS = BASE_ADDRESS + 24
DIRECTIONS_ADDRESS = BASE_ADDRESS + 48

def write_float32(address: int, value: float) -> str:
    return f"write float32 {hex(address)} {value}"

def set_x(player_id: int, x: float) -> str:
    return write_float32(X_COORDS_ADDRESS + player_id * SIZEOF_FLOAT, x)

def set_y(player_id: int, y: float) -> str:
    return write_float32(Y_COORDS_ADDRESS + player_id * SIZEOF_FLOAT, y)

def set_position(player_id: int, x: float, y: float) -> str:
    return sequence([
        set_x(player_id, x),
        set_y(player_id, y),
    ])

def set_direction_raw(player_id: int, direction: float) -> str:
    return write_float32(DIRECTIONS_ADDRESS + player_id * SIZEOF_FLOAT, direction)

def set_direction_conventional(player_id: int, conventional_direction: float) -> str:
    return set_direction_raw(player_id, conventional_direction + math.pi / 2)

def sequence(commands: list[str]) -> str:
    return ";".join(commands)

def scanmem_program(scenario_commands: list[str]) -> str:
    return sequence(SETUP_COMMANDS + scenario_commands + TEARDOWN_COMMANDS)

SETUP_COMMANDS: list[str] = [
    "option endianness 1",
]

TEARDOWN_COMMANDS: list[str] = [
    "exit",
]

scanmem_command: str = scanmem_program([
    set_position(RED, 50, 50),
    set_direction_conventional(RED, 0),
    set_position(YELLOW, 50, 100),
    set_direction_conventional(YELLOW, 0),
    set_position(GREEN, 50, 150),
    set_direction_conventional(GREEN, 0),
])

print("BEGIN scanmem program")
print()
print("    ", scanmem_command)
print()
print("END scanmem program")
print()

subprocess.run([ "scanmem", process_id, "--errexit", "--command", scanmem_command ])
