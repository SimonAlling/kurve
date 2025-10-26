#!/usr/bin/env python3
# Usage: see the Git history for this script.

import math
import subprocess
import time

RED = 0
YELLOW = 1
ORANGE = 2
GREEN = 3
PINK = 4
BLUE = 5
NUMBER_OF_PLAYERS = 6

SIZEOF_FLOAT = 4

BASE_ADDRESS = 0x7FFFD8010FF6  # Rendered as "7fffd8010ff6" in scanmem.

space_for_x_coordinates = NUMBER_OF_PLAYERS * SIZEOF_FLOAT
space_for_y_coordinates = NUMBER_OF_PLAYERS * SIZEOF_FLOAT

x_coordinates_address = BASE_ADDRESS
y_coordinates_address = BASE_ADDRESS + space_for_x_coordinates
directions_address = BASE_ADDRESS + space_for_x_coordinates + space_for_y_coordinates


def write_float32(address: int, value: float) -> str:
    return f"write float32 {hex(address)} {value}"


def set_x(player_id: int, x: float) -> str:
    return write_float32(x_coordinates_address + player_id * SIZEOF_FLOAT, x)


def set_y(player_id: int, y: float) -> str:
    return write_float32(y_coordinates_address + player_id * SIZEOF_FLOAT, y)


def set_position(player_id: int, x: float, y: float) -> str:
    return sequence(
        [
            set_x(player_id, x),
            set_y(player_id, y),
        ],
    )


def set_direction_raw(player_id: int, direction: float) -> str:
    return write_float32(directions_address + player_id * SIZEOF_FLOAT, direction)


def set_direction_conventional(player_id: int, conventional_direction: float) -> str:
    return set_direction_raw(player_id, conventional_direction + math.pi / 2)


def sequence(commands: list[str]) -> str:
    return ";".join(commands)


def scanmem_program(scenario_commands: list[str]) -> str:
    SETUP_COMMANDS: list[str] = [
        "option endianness 1",
    ]

    TEARDOWN_COMMANDS: list[str] = [
        "exit",
    ]

    return sequence(SETUP_COMMANDS + scenario_commands + TEARDOWN_COMMANDS)


scanmem_command: str = scanmem_program(
    [
        set_position(RED, 200, 50),
        set_direction_conventional(RED, 0),
        set_position(YELLOW, 200, 100),
        set_direction_conventional(YELLOW, 0),
        set_position(GREEN, 200, 150),
        set_direction_conventional(GREEN, 0),
    ],
)

print("BEGIN scanmem program")
print()
print("    ", scanmem_command)
print()
print("END scanmem program")
print()

proc = subprocess.Popen(
    ["dosbox", "docs/original-game/ZATACKA.EXE"],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)

WINDOW_MATCHES = ["DOSBox", "DOSBox Staging", "DOSBox-X"]


def find_and_focus(timeout=15.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        for needle in WINDOW_MATCHES:
            # search returns one id per line; --sync waits until a match exists
            res = subprocess.run(
                ["xdotool", "search", "--onlyvisible", "--name", needle],
                capture_output=True,
                text=True,
            )
            if res.returncode == 0 and res.stdout.strip():
                # pick the most recent window id (last line)
                wid = res.stdout.strip().splitlines()[-1]
                # Activate and focus
                subprocess.run(["xdotool", "windowactivate", "--sync", wid])
                subprocess.run(["xdotool", "windowfocus", wid])
                return wid
        time.sleep(0.3)
    return None


wid = find_and_focus()
if not wid:
    print("Warning: couldn't find/focus the DOSBox window; key sends may fail.")


time.sleep(1.0)  # small settle time after focus


def key(*keys):
    subprocess.run(["xdotool", "key", *keys])


def type_text(s):
    subprocess.run(["xdotool", "type", s])


time.sleep(1)
key("space")
time.sleep(1)
key("1")
time.sleep(1)
key("Ctrl")
time.sleep(1)
key("Left")
time.sleep(1)
key("space")
time.sleep(4)

subprocess.run(
    ["sudo", "scanmem", str(proc.pid), "--errexit", "--command", scanmem_command],
)
