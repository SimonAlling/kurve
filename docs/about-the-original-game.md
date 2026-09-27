# About the original game

This document outlines our understanding of [the 1995 MS-DOS game _Achtung, die Kurve!_][oldgames], also known as `ZATACKA.EXE` (referred to by us as "the original game").

## Memory layout

> [!NOTE]
> We refer to the address of Red's x coordinate as the **base address**.
> Offsets are relative to it.

| Offset | Content                               | Type    |
|--------|---------------------------------------|---------|
|      0 | Red's x                               | float32 |
|      4 | Yellow's x                            | float32 |
|      8 | Orange's x                            | float32 |
|     12 | Green's x                             | float32 |
|     16 | Pink's x                              | float32 |
|     20 | Blue's x                              | float32 |
|     24 | Red's y                               | float32 |
|     28 | Yellow's y                            | float32 |
|     32 | Orange's y                            | float32 |
|     36 | Green's y                             | float32 |
|     40 | Pink's y                              | float32 |
|     44 | Blue's y                              | float32 |
|     48 | Red's direction[^1]                   | float32 |
|     52 | Yellow's direction[^1]                | float32 |
|     56 | Orange's direction[^1]                | float32 |
|     60 | Green's direction[^1]                 | float32 |
|     64 | Pink's direction[^1]                  | float32 |
|     68 | Blue's direction[^1]                  | float32 |

[^1]: Counter-clockwise radians zeroed at down/south, _not_ normalized/clamped.

### Finding addresses

Below follows a summary of how to locate game state in memory, using **Red's x coordinate** as an example.

This works with [DOSBox] 0.74-3 and [scanmem] 0.17 in Ubuntu 24.04, including in WSL on Windows 11 25H2.

  1. Temporarily [disable ASLR]:

     ```bash
     echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
     ```

  1. Launch the original game:

     ```bash
     # Native Linux:
     dosbox docs/original-game/ZATACKA.EXE -userconf -conf ./tools/dosbox-linux.conf

     # WSL:
     dosbox docs/original-game/ZATACKA.EXE -userconf -conf ./tools/dosbox-wsl.conf
     ```

     > [!NOTE]
     > See `git log --grep memsize` for more info about the difference between native Linux and WSL.

  1. In another terminal:

         sudo scanmem `pgrep dosbox` --errexit --command 'option endianness 1;option scan_data_type float32'

  1. Join with Red and another player, then start the game.

  1. Optionally spam Ctrl + F11 to slow down the simulation.

  1. Make sure both players are moving roughly horizontally to the right.

  1. Pause the emulation by pressing Alt + Pause.

     > [!TIP]
     > If the keyboard doesn't have a Pause key, remap e.g. Insert:
     >
     > ```bash
     > xmodmap -e "keycode 118 = Pause"
     > ```

  1. In scanmem, perform a rough initial search for candidate x values:

         > 50..560

  1. Resume the game briefly, then pause it again.

  1. Keep only the values that have increased since the previous command:

         > +

     Repeat this a couple of times so that only a few matches remain.

  1. Turn around with Red and move to the left for a while. Pause the game.

  1. Keep only the values that have _decreased_ since the previous command:

         > -

  1. It should say `info: we currently have 1 matches.` Use `list` to print it.

  1. The printed address (e.g. `0x7fffd8010ff6`) holds Red's x coordinate.

## Tooling

### Summary

| Use case         | Tool                       |
|------------------|----------------------------|
| Stage a scenario | `tools/scenario.py`        |
| View game state  | `tools/show-game-state.sh` |

See `git log --grep FILE_NAME_OF_THE_TOOL` for info about each tool.

### History

See #93 and `git log 22da84b1d5a2fae47b0c322925dbb84e9f8badae^.. -- tools/`.
In particular, these PRs tell the story quite well:

  1. #164
  1. #165
  1. #170
  1. #183
  1. #187
  1. #211
  1. #216
  1. #223
  1. #231
  1. #237

[oldgames]: https://www.oldgames.sk/en/game/achtung-die-kurve
[disable ASLR]: https://askubuntu.com/questions/318315/how-can-i-temporarily-disable-aslr-address-space-layout-randomization/318476#318476
[DOSBox]: https://www.dosbox.com/index.php
[scanmem]: https://github.com/scanmem/scanmem
