#!/usr/bin/env python3
# Usage: see the Git history for this script.

from math import pi
import struct
import subprocess
import sys

from dosbox_memory import find_base_address, read_memory

PLAYERS = [
    ("🟥", "Red"),
    ("🟨", "Yellow"),
    ("🟧", "Orange"),
    ("🟩", "Green"),
    ("🟪", "Pink"),
    ("🟦", "Blue"),
]
NUMBER_OF_PLAYERS = len(PLAYERS)

SIZE_OF_FLOAT = 4
NUMBER_OF_STATE_COMPONENTS = 3  # x, y, direction
SIZE_OF_GAME_STATE = NUMBER_OF_STATE_COMPONENTS * NUMBER_OF_PLAYERS * SIZE_OF_FLOAT

COLUMN_WIDTH = 20

ARROWS = [
    "↓",
    "↘",
    "→",
    "↗",
    "↑",
    "↖",
    "←",
    "↙",
]
NUMBER_OF_ARROWS = len(ARROWS)


def arrow_for_dir(
    raw_direction: float,
) -> str:
    aligned_direction = (
        # The angle "almost 2π" should be represented by the downward arrow, i.e. index 0, not index n - 1. This addition "pushes it over the edge". The addition will be negated below by rounding down.
        raw_direction + pi / NUMBER_OF_ARROWS
    )
    cycle = 2 * pi
    arrow_index = int((aligned_direction % cycle) / cycle * NUMBER_OF_ARROWS)
    return ARROWS[arrow_index]


def find_dosbox_pid() -> int | None:
    res = subprocess.run(
        ["pgrep", "--newest", "dosbox"], capture_output=True, text=True
    )
    if res.returncode != 0:
        return None
    return int(res.stdout.strip())


def read_game_state(dosbox_pid: int) -> bytes:
    base_address = find_base_address(dosbox_pid)
    if base_address is None:
        print(
            "⚠️  Couldn't find DOSBox's emulated RAM. Maybe the game is currently starting."
        )
        sys.exit(1)
    return read_memory(dosbox_pid, base_address, SIZE_OF_GAME_STATE)


def main():
    dosbox_pid = find_dosbox_pid()
    if dosbox_pid is None:
        print("⚠️  Process not found. Is the game running?")
        sys.exit(1)

    try:
        raw_bytes = read_game_state(dosbox_pid)
    except FileNotFoundError:
        print("⚠️  Process not found. Maybe the game just exited.")
        sys.exit(1)
    except PermissionError:
        print(
            "⚠️  Not allowed to read DOSBox's memory. Try running this script with sudo."
        )
        sys.exit(1)
    except OSError as err:
        print(f"⚠️  Read memory failed. Reason: {err}")
        sys.exit(1)

    values = struct.unpack(f"<{len(raw_bytes) // SIZE_OF_FLOAT}f", raw_bytes)
    xs = values[0:NUMBER_OF_PLAYERS]
    ys = values[NUMBER_OF_PLAYERS : 2 * NUMBER_OF_PLAYERS]
    dirs = values[2 * NUMBER_OF_PLAYERS : 3 * NUMBER_OF_PLAYERS]

    # Table head:
    print(
        "          ",
        "x".ljust(COLUMN_WIDTH),
        "y".ljust(COLUMN_WIDTH),
        "Direction (0 = down)".ljust(COLUMN_WIDTH),
    )

    # Table body:
    for player_id in range(0, NUMBER_OF_PLAYERS):
        x = xs[player_id]
        y = ys[player_id]
        dir = dirs[player_id]
        print(
            PLAYERS[player_id][0],
            PLAYERS[player_id][1].ljust(7),
            str(x).ljust(COLUMN_WIDTH),
            str(y).ljust(COLUMN_WIDTH),
            arrow_for_dir(dir),
            str(dir).ljust(COLUMN_WIDTH),
        )


if __name__ == "__main__":
    main()
