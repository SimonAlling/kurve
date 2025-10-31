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


def parse_dump(text: str) -> bytes:
    all_bytes: list[int] = []

    for line in text.splitlines():
        for token in HEX_BYTE_RE.findall(line):
            all_bytes.append(int(token, 16))

    return bytes(all_bytes)


def to_float32_le(b: bytes) -> float:
    return struct.unpack("<f", b)[0]


def chunk_bytes(bs: bytes, n: int) -> list[bytes]:
    return [bs[i : i + n] for i in range(0, len(bs), n) if len(bs[i : i + n]) == n]


def chunk_floats(bs: list[float], n: int) -> list[list[float]]:
    return [bs[i : i + n] for i in range(0, len(bs), n) if len(bs[i : i + n]) == n]


ARROWS = [
    "⬇️",
    "↘️",
    "➡️",
    "↗️",
    "⬆️",
    "↖️",
    "⬅️",
    "↙️",
]
NUMBER_OF_ARROWS = len(ARROWS)


def illustrate_dir(
    raw_direction: float,
) -> str:
    normalized_direction = (raw_direction + pi / NUMBER_OF_ARROWS) % (2 * pi)
    return ARROWS[int(normalized_direction / (2 * pi) * NUMBER_OF_ARROWS)]


def main():
    text: str = sys.stdin.read()

    if text == "":
        print("⚠️  Empty input on stdin. Is the game running?")
        sys.exit(1)

    raw_bytes: bytes = parse_dump(text)

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
        "Direction (raw)".ljust(COLUMN_WIDTH),
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
            illustrate_dir(dir) + " ",
            str(dir).ljust(COLUMN_WIDTH),
        )


if __name__ == "__main__":
    main()
