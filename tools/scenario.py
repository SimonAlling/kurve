#!/usr/bin/env python3
# Usage: see the Git history for this script.

from enum import Enum
from math import pi
import os
import subprocess
import sys
import time
from typing import Callable, NoReturn, TypedDict

path_to_original_game = sys.argv[1]
raw_base_address = sys.argv[2]  # e.g. 7fffd8010ff6
additional_dosbox_config_file = sys.argv[3]  # e.g. tools/dosbox-linux.conf

ENV_VAR_DRY_RUN = "DRY_RUN"


class PlayerId(Enum):
    RED = 0
    YELLOW = 1
    ORANGE = 2
    GREEN = 3
    PINK = 4
    BLUE = 5


NUMBER_OF_PLAYERS = len(PlayerId)


def exitBecauseBlueIsNotSupported():
    print("❌ Blue (the player) isn't supported yet.")
    exit(1)


JOIN_PLAYER: dict[PlayerId, Callable[[], None | NoReturn]] = {
    PlayerId.RED: lambda: press_key("1"),
    PlayerId.YELLOW: lambda: press_key("Ctrl"),
    PlayerId.ORANGE: lambda: press_key("M"),
    PlayerId.GREEN: lambda: press_key("Left"),
    PlayerId.PINK: lambda: press_key("KP_Divide"),
    PlayerId.BLUE: exitBecauseBlueIsNotSupported,
}

SIZEOF_FLOAT = 4

space_for_x_coordinates = NUMBER_OF_PLAYERS * SIZEOF_FLOAT
space_for_y_coordinates = NUMBER_OF_PLAYERS * SIZEOF_FLOAT

base_address = int(raw_base_address, 16)
x_coordinates_address = base_address
y_coordinates_address = base_address + space_for_x_coordinates
directions_address = base_address + space_for_x_coordinates + space_for_y_coordinates


PlayerState = TypedDict("PlayerState", {"x": float, "y": float, "direction": float})

SCENARIO: dict[PlayerId, PlayerState] = {
    PlayerId.RED: {
        "x": 200,
        "y": 50,
        "direction": pi / 2,
    },
    PlayerId.YELLOW: {
        "x": 200,
        "y": 100,
        "direction": pi / 2,
    },
    PlayerId.GREEN: {
        "x": 200,
        "y": 150,
        "direction": pi / 2,
    },
}


def write_float32(address: int, value: float) -> str:
    return f"write float32 {hex(address)} {value}"


def set_x(player_id: PlayerId, x: float) -> str:
    return write_float32(x_coordinates_address + player_id.value * SIZEOF_FLOAT, x)


def set_y(player_id: PlayerId, y: float) -> str:
    return write_float32(y_coordinates_address + player_id.value * SIZEOF_FLOAT, y)


def set_position(player_id: PlayerId, x: float, y: float) -> str:
    return sequence(
        [
            set_x(player_id, x),
            set_y(player_id, y),
        ],
    )


def set_direction(player_id: PlayerId, direction: float) -> str:
    return write_float32(directions_address + player_id.value * SIZEOF_FLOAT, direction)


def set_player_state(player_id: PlayerId, x: float, y: float, direction: float) -> str:
    return sequence(
        [
            set_position(player_id, x, y),
            set_direction(player_id, direction),
        ],
    )


def sequence(commands: list[str]) -> str:
    return ";".join(commands)


def make_scanmem_program(scenario_commands: list[str]) -> str:
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


def check_that_dosbox_is_not_already_open() -> None:
    window_id = find_dosbox(have_just_launched_it=False)
    if window_id is not None:
        print("❌ DOSBox seems to already be open. Please close it.")
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


def find_and_focus_dosbox() -> str:
    window_id = find_dosbox(have_just_launched_it=True)
    if window_id is None:
        print("❌ Couldn't find the DOSBox window.")
        exit(1)
    subprocess.run(["xdotool", "windowactivate", "--sync", window_id])
    subprocess.run(["xdotool", "windowfocus", window_id])
    return window_id


def find_dosbox(have_just_launched_it: bool) -> str | None:
    res = subprocess.run(
        [
            "xdotool",
            "search",
        ]
        + (
            [
                "--sync",
                "--onlyvisible",
            ]
            if have_just_launched_it
            else []
        )
        + [
            "--name",
            "DOSBox.+ZATACKA",
        ],
        capture_output=True,
        text=True,
    )
    if res.returncode == 0 and res.stdout.strip():
        window_id: str = res.stdout.strip().splitlines()[-1]  # (most recent window ID)
        return window_id
    return None


def stage_scenario(process_id: int, scanmem_program: str) -> None:
    subprocess.run(
        ["sudo", "scanmem", str(process_id), "--errexit", "--command", scanmem_program],
    )


def press_key(key: str) -> None:
    subprocess.run(["xdotool", "key", key])


def launch_original_game_and_stage_scenario(
    path_to_original_game: str,
    participating_players: list[PlayerId],
    scanmem_program: str,
) -> None:
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

    time.sleep(2)  # Prevents intermittent failure to find/focus DOSBox.

    find_and_focus_dosbox()

    time.sleep(2)
    press_key("space")
    time.sleep(0.5)
    for player_id in participating_players:
        JOIN_PLAYER[player_id]()
    time.sleep(0.5)
    press_key("space")
    time.sleep(len(participating_players) + 0.1)

    stage_scenario(proc.pid, scanmem_program)


def main() -> None:
    is_dry_run = bool(os.environ.get(ENV_VAR_DRY_RUN))

    subprocess.run(
        ["sudo", "true"]
    )  # Fail early if password hasn't been entered recently.

    check_that_dosbox_config_file_exists()  # DOSBox 0.74.3 silently ignores if the specified config file doesn't exist.

    if not is_dry_run:
        check_that_dosbox_is_not_already_open()

    check_address_space_layout_randomization()

    scanmem_program: str = make_scanmem_program(
        [
            set_player_state(
                player_id,
                x=player_state["x"],
                y=player_state["y"],
                direction=player_state["direction"],
            )
            for player_id, player_state in SCENARIO.items()
        ],
    )

    print("BEGIN scanmem program")
    print()
    print(scanmem_program)
    print()
    print("END scanmem program")
    print()

    participating_players = list(SCENARIO.keys())

    if is_dry_run:
        print(
            f"💡 Environment variable {ENV_VAR_DRY_RUN} specified. Not launching original game."
        )
        return

    launch_original_game_and_stage_scenario(
        path_to_original_game,
        participating_players,
        scanmem_program,
    )


if __name__ == "__main__":
    main()
