#!/usr/bin/env python3
# Usage: see the Git history for this script.

from math import pi
import os
import subprocess
import sys
import time

process_id_or_path_to_original_game = sys.argv[1]
raw_base_address = sys.argv[2]  # e.g. 7fffd8010ff6
additional_dosbox_config_file = sys.argv[3]  # e.g. tools/dosbox-linux.conf

subprocess.run(["sudo", "true"])  # Fail early if password hasn't been entered recently.

RED = 0
YELLOW = 1
ORANGE = 2
GREEN = 3
PINK = 4
BLUE = 5
NUMBER_OF_PLAYERS = 6

SIZEOF_FLOAT = 4

space_for_x_coordinates = NUMBER_OF_PLAYERS * SIZEOF_FLOAT
space_for_y_coordinates = NUMBER_OF_PLAYERS * SIZEOF_FLOAT

base_address = int(raw_base_address, 16)
x_coordinates_address = base_address
y_coordinates_address = base_address + space_for_x_coordinates
directions_address = base_address + space_for_x_coordinates + space_for_y_coordinates


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


def set_direction(player_id: int, direction: float) -> str:
    return write_float32(directions_address + player_id * SIZEOF_FLOAT, direction)


def set_player_state(player_id: int, x: float, y: float, direction: float) -> str:
    return sequence(
        [
            set_position(player_id, x, y),
            set_direction(player_id, direction),
        ],
    )


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


def check_that_dosbox_config_file_exists() -> None:
    if not os.path.isfile(additional_dosbox_config_file):
        print(f"❌ DOSBox config file '{additional_dosbox_config_file}' not found.")
        exit(1)


def check_address_space_layout_randomization() -> None:
    try:
        aslr_file = open(file="/proc/sys/kernel/randomize_va_space", mode="r")
        content = aslr_file.read(1)  # We expect a single digit (0, 1 or 2).
        if content != "0":
            print(
                "⚠️  Address space layout randomization (ASLR) seems to be enabled, which may cause this script not to work.",
            )
            print("💡 Solution: temporarily disable ASLR while using this script.")
    except OSError as err:
        print(
            f"⚠️  Could not check if address space layout randomization (ASLR) is disabled. Reason: {str(err)}"
        )


def find_and_focus_dosbox(timeout: float = 15.0) -> str | None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        res = subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--name", "DOSBox.+ZATACKA"],
            capture_output=True,
            text=True,
        )
        if res.returncode == 0 and res.stdout.strip():
            wid: str = res.stdout.strip().splitlines()[-1]  # (most recent window ID)
            subprocess.run(["xdotool", "windowactivate", "--sync", wid])
            subprocess.run(["xdotool", "windowfocus", wid])
            return wid
    return None


def press_key(key: str) -> None:
    subprocess.run(["xdotool", "key", key])


def prepare_and_get_process_id(process_id_or_path_to_original_game: str) -> str:
    if "ZATACKA.EXE" in process_id_or_path_to_original_game:
        path_to_original_game = process_id_or_path_to_original_game
        print(f"🚀 Launching original game at {path_to_original_game} …")

        proc = subprocess.Popen(
            [
                "dosbox",
                "-userconf",
                "-conf",
                additional_dosbox_config_file,
                path_to_original_game,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        window_id = find_and_focus_dosbox()
        if window_id is None:
            print("Warning: couldn't find/focus the DOSBox window; key sends may fail.")

        KEY_RED_LEFT = "1"
        KEY_YELLOW_LEFT = "Ctrl"
        KEY_GREEN_LEFT = "Left"

        time.sleep(2)
        press_key("space")
        time.sleep(0.5)
        # Players need to join here in order to be able to participate in the staged scenario.
        press_key(KEY_RED_LEFT)
        press_key(KEY_YELLOW_LEFT)
        press_key(KEY_GREEN_LEFT)
        time.sleep(0.5)
        press_key("space")
        time.sleep(3.1)

        return str(proc.pid)

    else:
        process_id = process_id_or_path_to_original_game
        print(f"📎 Attaching to already running DOSBox with PID {process_id} …")
        return process_id


scanmem_command: str = scanmem_program(
    [
        set_player_state(RED, x=200, y=50, direction=pi / 2),
        set_player_state(YELLOW, x=200, y=100, direction=pi / 2),
        set_player_state(GREEN, x=200, y=150, direction=pi / 2),
    ],
)

check_that_dosbox_config_file_exists()  # DOSBox 0.74.3 silently ignores if the specified config file doesn't exist.

check_address_space_layout_randomization()

process_id: str = prepare_and_get_process_id(process_id_or_path_to_original_game)

print("BEGIN scanmem program")
print()
print("    ", scanmem_command)
print()
print("END scanmem program")
print()

subprocess.run(
    ["sudo", "scanmem", process_id, "--errexit", "--command", scanmem_command],
)
