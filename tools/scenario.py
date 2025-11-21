#!/usr/bin/env python3
# Usage: see the Git history for this script.

from enum import Enum
import json
import os
import subprocess
import sys
import time
from typing import Callable, Literal, NoReturn, TypedDict

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


def stage_scenario(process_id: int, gdb_program_file: str) -> None:
    subprocess.Popen(
        [
            "sudo",
            "gdb",
            "--batch",
            "--pid",
            str(process_id),
            "--command",
            gdb_program_file,
        ],
        # We have to suppress stdio, otherwise gdb kind of doesn't really quit and makes everything typed into the terminal invisible, at least in WSL.
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def press_key(key: str) -> None:
    subprocess.run(["xdotool", "key", key])


def launch_original_game_and_stage_scenario(
    path_to_original_game: str,
    participating_players: list[PlayerId],
    gdb_program_file: str,
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

    stage_scenario(proc.pid, gdb_program_file)

    time.sleep(2)
    press_key("space")
    time.sleep(0.5)
    for player_id in participating_players:
        JOIN_PLAYER[player_id]()
    time.sleep(0.5)
    press_key("space")


class CompiledScenario(TypedDict):
    participatingPlayersById: list[int]
    gdbProgram: str


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
        ["node", path_to_glue_javascript, raw_base_address],
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

    check_that_dosbox_config_file_exists()  # DOSBox 0.74.3 silently ignores if the specified config file doesn't exist.

    check_that_dosbox_is_not_already_open()

    check_address_space_layout_randomization()

    compiled_scenario = compile_scenario()

    gdb_program: str = compiled_scenario["gdbProgram"]

    participating_players = [
        PlayerId(i) for i in compiled_scenario["participatingPlayersById"]
    ]

    if is_dry_run:
        print("BEGIN gdb program")
        print()
        print(gdb_program)
        print()
        print("END gdb program")
        print()
        print(
            f"💡 Environment variable {ENV_VAR_DRY_RUN} specified. Not launching original game."
        )
        return

    GDB_PROGRAM_FILE = ".compiled-scenario.gdb"
    with open(GDB_PROGRAM_FILE, "+w") as f:
        print(f"📝 Writing {GDB_PROGRAM_FILE} …")
        f.write(gdb_program)

    launch_original_game_and_stage_scenario(
        path_to_original_game,
        participating_players,
        GDB_PROGRAM_FILE,
    )


if __name__ == "__main__":
    main()
