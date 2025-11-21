#!/usr/bin/env python3

from math import pi
import re
import struct
import sys

HEX_BYTE_RE = re.compile(r"\b[0-9A-Fa-f]{2}\b")

PLAYERS = [
    ("🟥", "Red"),
    ("🟨", "Yellow"),
    ("🟧", "Orange"),
    ("🟩", "Green"),
    ("🟪", "Pink"),
    ("🟦", "Blue"),
]
NUMBER_OF_PLAYERS = len(PLAYERS)

COLUMN_WIDTH = 20


def parse_dump(lines: list[str]) -> bytes:
    all_bytes: list[int] = []

    found_data: bool = False
    for line in lines:
        if found_data:
            for token in HEX_BYTE_RE.findall(line):
                all_bytes.append(int(token, 16))
        if line.startswith("> dump"):
            found_data = True

    return bytes(all_bytes)


def is_process_not_found_error(lines: list[str]) -> bool:
    return any(
        [line.startswith("error: ") and "No such process" in line for line in lines]
    )


def is_some_scanmem_error(lines: list[str]) -> bool:
    return any(
        [line.startswith("error: ") and "read memory failed" in line for line in lines]
    )


def to_float32_le(b: bytes) -> float:
    return struct.unpack("<f", b)[0]


def chunk_bytes(bs: bytes, n: int) -> list[bytes]:
    return [bs[i : i + n] for i in range(0, len(bs), n) if len(bs[i : i + n]) == n]


def chunk_floats(bs: list[float], n: int) -> list[list[float]]:
    return [bs[i : i + n] for i in range(0, len(bs), n) if len(bs[i : i + n]) == n]


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


def main():
    text: str = sys.stdin.read()

    lines = text.splitlines()

    if is_process_not_found_error(lines):
        print("⚠️  Process not found. Is the game running?")
        sys.exit(1)

    if is_some_scanmem_error(lines):
        print("⚠️  Read memory failed. Maybe the game is currently starting.")
        sys.exit(1)

    raw_bytes: bytes = parse_dump(lines)

    values: list[float] = []
    offset: int = 0

    for quad in chunk_bytes(raw_bytes, 4):
        try:
            f = to_float32_le(quad)
        except Exception:
            f = float("nan")
        values.append(f)
        offset += 4

    [xs, ys, dirs] = chunk_floats(values, NUMBER_OF_PLAYERS)

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
