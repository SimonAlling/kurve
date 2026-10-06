#!/usr/bin/env python3
# Usage: see the Git history for this script.

from enum import Enum
import json
import os
import subprocess
import sys
import time
from typing import Callable, Literal, TypedDict

path_to_original_game = sys.argv[1]

ENV_VAR_DRY_RUN = "DRY_RUN"

BASE_ADDRESS_PLACEHOLDER = "BASE_ADDRESS_PLACEHOLDER_TO_BE_FILLED_IN_AFTER_COMPILATION"


class PlayerId(Enum):
    RED = 0
    YELLOW = 1
    ORANGE = 2
    GREEN = 3
    PINK = 4
    BLUE = 5


JOIN_PLAYER: dict[PlayerId, Callable[[], None]] = {
    PlayerId.RED: lambda: press_key("1"),
    PlayerId.YELLOW: lambda: press_key("Ctrl"),
    PlayerId.ORANGE: lambda: press_key("M"),
    PlayerId.GREEN: lambda: press_key("Left"),
    PlayerId.PINK: lambda: press_key("KP_Divide"),
    PlayerId.BLUE: lambda: click_mouse_button(),
}


def check_that_dosbox_is_not_already_open() -> None:
    window_id = find_dosbox(have_just_launched_it=False)
    if window_id is not None:
        print("❌ DOSBox seems to already be open. Please close it.")
        exit(1)


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


# DOSBox emulates the guest's RAM as one contiguous block in its own (host) memory, so a guest address is just an offset from the start of that block.
BIOS_DATE = b"01/01/92"  # DOSBox's hardcoded BIOS date.
GUEST_ADDRESS_OF_BIOS_DATE = (
    0xFFFF5  # Like a real PC BIOS, DOSBox puts its BIOS date at guest address 0xFFFF5.
)
GUEST_ADDRESS_OF_GAME_STATE = (
    0xCFE6  # Where the original game stores the state that we're concerned with.
)


def find_base_address(dosbox_pid: int) -> int:
    """
    Returns the host address of the game state, i.e. what the relative addresses in the gdb program are relative to.
    """
    return find_guest_ram(dosbox_pid) + GUEST_ADDRESS_OF_GAME_STATE


def find_guest_ram(dosbox_pid: int) -> int:
    """
    Returns the host address where DOSBox's emulated RAM starts, by searching DOSBox's memory for the BIOS date.
    """
    # We can read DOSBox's memory without sudo because DOSBox is our child process.
    with (
        open(f"/proc/{dosbox_pid}/maps") as maps,
        open(f"/proc/{dosbox_pid}/mem", "rb", buffering=0) as mem,
    ):
        for line in maps:
            # Each line describes a memory region, e.g.:
            #
            #     7fffac5f8000-7fffad5f9000 rw-p 00000000 00:00 0
            #
            address_range, permissions, *_ = line.split()
            if not permissions.startswith("rw"):
                continue  # The guest RAM is writable, so this can't be it.
            start, end = (int(x, 16) for x in address_range.split("-"))
            try:
                mem.seek(start)
                region = mem.read(end - start)
            except OSError:
                continue  # Some regions just can't be read.
            offset_in_region = region.find(BIOS_DATE)
            if offset_in_region != -1:
                host_address_of_bios_date = start + offset_in_region
                return host_address_of_bios_date - GUEST_ADDRESS_OF_BIOS_DATE
    print("❌ Couldn't find DOSBox's emulated RAM.")
    exit(1)


def stage_scenario(process_id: int, gdb_program_file: str) -> None:
    subprocess.Popen(
        ["sudo", "gdb", "--pid", str(process_id), "--command", gdb_program_file],
        # We have to suppress stdio, otherwise gdb kind of takes over the terminal permanently and makes everything typed into it invisible (in WSL on my Windows PC as well as on my Ubuntu laptop).
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def press_key(key: str) -> None:
    subprocess.run(["xdotool", "key", key])


def click_mouse_button() -> None:
    mouse_button = 1  # (left click)
    subprocess.run(["xdotool", "mousedown", str(mouse_button)])
    subprocess.run(["xdotool", "mouseup", str(mouse_button)])


def with_base_address(
    gdb_program_with_base_address_placeholder: str, base_address: int
) -> str:
    REPLACE_ALL_OCCURRENCES = -1
    return gdb_program_with_base_address_placeholder.replace(
        BASE_ADDRESS_PLACEHOLDER, hex(base_address), REPLACE_ALL_OCCURRENCES
    )


def launch_original_game_and_stage_scenario(
    path_to_original_game: str,
    participating_players: list[PlayerId],
    gdb_program_with_base_address_placeholder: str,
) -> None:
    print(f"🚀 Launching original game at {path_to_original_game} …")

    proc = subprocess.Popen(
        [
            "dosbox",
            path_to_original_game,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    time.sleep(
        2
    )  # Prevents intermittent failure to find base address and find/focus DOSBox window.

    base_address = find_base_address(proc.pid)

    GDB_PROGRAM_FILE = ".compiled-scenario.gdb"
    with open(GDB_PROGRAM_FILE, "+w") as f:
        print(f"📝 Writing {GDB_PROGRAM_FILE} …")
        f.write(
            with_base_address(gdb_program_with_base_address_placeholder, base_address)
        )

    find_and_focus_dosbox()

    stage_scenario(proc.pid, GDB_PROGRAM_FILE)

    time.sleep(2)
    press_key("space")
    time.sleep(0.5)
    for player_id in participating_players:
        JOIN_PLAYER[player_id]()
    time.sleep(0.5)
    press_key("space")


class CompiledScenario(TypedDict):
    participatingPlayersById: list[int]
    gdbProgramWithBaseAddressPlaceholder: str


type CompilationResultAsJson = CompilationSuccess | CompilationFailure


class CompilationSuccess(TypedDict):
    compilationSuccess: Literal[True]
    compiledScenario: CompiledScenario


class CompilationFailure(TypedDict):
    compilationSuccess: Literal[False]
    compilationErrorMessage: str


def compile_scenario() -> CompiledScenario:
    npm_process = subprocess.run(["npm", "run", "build:scenario-in-original-game"])
    npm_exit_code = npm_process.returncode
    if npm_exit_code != 0:
        print("❌ Elm compilation failed.")
        exit(1)

    path_to_glue_javascript = os.path.join(
        os.path.dirname(sys.argv[0]), "compile-scenario-glue.cjs"
    )

    node_process = subprocess.run(
        ["node", path_to_glue_javascript, BASE_ADDRESS_PLACEHOLDER],
        encoding="utf-8",
        capture_output=True,
    )
    node_exit_code = node_process.returncode
    if node_exit_code != 0:
        print(
            f"❌ Unexpected exit code from {path_to_glue_javascript}: {node_exit_code}"
        )
        print(node_process.stderr)
        exit(1)

    try:
        result: CompilationResultAsJson = json.loads(
            node_process.stdout
        )  # This is blind trust. 👀
    except json.JSONDecodeError as e:
        print("❌ Scenario compilation result could not be parsed.")
        print(e)
        exit(1)

    if result["compilationSuccess"] is True:
        return result["compiledScenario"]
    else:
        print("❌ Scenario compilation failed.")
        print(result["compilationErrorMessage"])
        exit(1)


def main() -> None:
    is_dry_run = bool(os.environ.get(ENV_VAR_DRY_RUN))

    subprocess.run(
        ["sudo", "true"]
    )  # Fail early if password hasn't been entered recently.

    check_that_dosbox_is_not_already_open()

    compiled_scenario = compile_scenario()

    gdb_program_with_base_address_placeholder: str = compiled_scenario[
        "gdbProgramWithBaseAddressPlaceholder"
    ]

    participating_players = [
        PlayerId(i) for i in compiled_scenario["participatingPlayersById"]
    ]

    if is_dry_run:
        print("BEGIN gdb program")
        print()
        print(gdb_program_with_base_address_placeholder)
        print()
        print("END gdb program")
        print()
        print(
            f"💡 Environment variable {ENV_VAR_DRY_RUN} specified. Not launching original game."
        )
        return

    if PlayerId.BLUE in participating_players:
        print(
            "💡 Blue is participating; make sure to keep the cursor within the DOSBox window."
        )

    launch_original_game_and_stage_scenario(
        path_to_original_game,
        participating_players,
        gdb_program_with_base_address_placeholder,
    )


if __name__ == "__main__":
    main()
