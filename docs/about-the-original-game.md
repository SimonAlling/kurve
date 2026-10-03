# About the original game

This document outlines our understanding of [the 1995 MS-DOS game _Achtung, die Kurve!_][oldgames], also known as `ZATACKA.EXE` (referred to by us as "the original game").

## Memory layout

> [!NOTE]
> We refer to the address of Red's x coordinate as the **base address**.
> Offsets are relative to it.

> [!NOTE]
> Player order is always 🟥 Red, 🟨 Yellow, 🟧 Orange, 🟩 Green, 🟪 Pink, 🟦 Blue.

| Offset | Content                               | Type        |
|--------|---------------------------------------|-------------|
|      0 | x coordinates                         | float[6]    |
|     24 | y coordinates                         | float[6]    |
|     48 | Directions[^directions]               | float[6]    |

[^directions]: Counter-clockwise radians zeroed at down/south, _not_ normalized/clamped.

### Finding addresses

Below follows a summary of how to locate game state in memory, using **Red's x coordinate** as an example.

This works with [DOSBox] 0.74-3 and [scanmem] 0.17 in Ubuntu 24.04, including in WSL on Windows 11 25H2.

  1. Temporarily [disable ASLR]:

     ```bash
     echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
     ```

  1. Launch the original game:

     #### Native Linux[^memsize]

     ```bash
     dosbox docs/original-game/ZATACKA.EXE -userconf -conf ./tools/dosbox-linux.conf
     ```

     #### WSL[^memsize]

     ```bash
     dosbox docs/original-game/ZATACKA.EXE -userconf -conf ./tools/dosbox-wsl.conf
     ```

     [^memsize]: See `git log --grep memsize` for more info about the difference between native Linux and WSL.

  1. In another terminal:

     ```bash
     sudo scanmem `pgrep dosbox` --errexit --command 'option endianness 1;option scan_data_type float32'
     ```

  1. Join with Red and another player, then start the game.

  1. Optionally spam Ctrl + F11 to slow down the simulation.

  1. Make sure both players are moving roughly horizontally to the right.

  1. Pause the emulation by pressing Alt + Pause[^pause].

     [^pause]: If the keyboard doesn't have a Pause key, remap e.g. Insert with `xmodmap -e "keycode 118 = Pause"`.

  1. In scanmem, perform a rough initial search for candidate x values:

         > 50..560

  1. Resume the game briefly, then pause it again.

  1. Keep only the values that have increased since the previous command:

         > +

     Repeat this a couple of times so that only a few matches remain.

  1. Turn around with Red and move to the left for a while. Pause the game.

  1. Keep only the values that have _decreased_ since the previous command:

         > -

     It should say `info: we currently have 1 matches.`

  1. Print the only remaining match:

         > list

     The printed address (e.g. `0x7fffd8010ff6`) holds Red's x coordinate.

## Tooling

### Summary

| Use case         | Tool                       |
|------------------|----------------------------|
| Stage a scenario | `tools/scenario.py`        |
| View game state  | `tools/show-game-state.sh` |

See `git log --grep FILE_NAME_OF_THE_TOOL` for info about each tool.

### History

See [#93] and `git log 22da84b1d5a2fae47b0c322925dbb84e9f8badae^.. -- tools/`.
In particular, these PRs tell the story quite well:

  1. [#164 - Add script for manipulating original game][#164]
  1. [#165 - Enable automation in scenario script][#165]
  1. [#170 - Add script for showing game state][#170]
  1. [#183 - Un-hardcode base address in tools][#183]
  1. [#187 - Make scenario script work in WSL on my Windows PC][#187]
  1. [#211 - Enforce automation in scenario script][#211]
  1. [#216 - Enable dry-running scenario script][#216]
  1. [#223 - Rewrite original-game scenario DSL in Elm][#223]
  1. [#231 - Replace scanmem with gdb in scenario script][#231]
  1. [#237 - Add support for Blue in scenario script][#237]

## Surprising behavior

### Overpainting

Somewhat counterintuitively, painting where another player has already painted is possible without dying.

In 2016, [Brage Salhus Bunk], Edvin Broman and I came up with [a theoretical "perfect overpainting"], which we finally [proved] possible in 2025:

<img alt="Demo of perfect overpainting" src="recordings/perfect-overpainting.png" width="320" />

See [`perfect-overpainting.mp4`] for the full round from which the animated image above was extracted.

Our clone has supported the perfect overpainting ever since 2aa51793d871d9ca334734e4e75cce2e8bc4e429.

<details>

<summary>ℹ️ How to reproduce</summary>

  1. Checkout c50dda59aa3dc81d7caecf7676ed3917ffe8513e.

  1. Define this scenario in `TheScenario.elm`:

     ```elm
     theScenario : Scenario
     theScenario =
         [ ( Red
           , { x = 100
             , y = 50
             , direction = -pi * 1 / 4
             }
           )
         , ( Yellow
           , { x = 100
             , y = 400
             , direction = pi / 2
             }
           )
         , ( Orange
           , { x = 20
             , y = 20
             , direction = pi * 1 / 4
             }
           )
         , ( Green
           , { x = 50
             , y = 100
             , direction = pi * 3 / 4
             }
           )
         ]
     ```

  1. Stage the scenario:

     ```bash
     BASE_ADDRESS=0x7fff… # See "Finding addresses" above. We've seen 0x7fffc1c65ff6 and 0x7fffac604ff6 work in WSL; and 0x7fffd8010ff6 in native Linux.
     ./tools/scenario.py docs/original-game/ZATACKA.EXE ${BASE_ADDRESS:?} tools/dosbox-wsl.conf
     ```

</details>

### Wall off-by-one error

It's possible to be up to (but not including) 1 pixel outside the **top and left wall**, although the Kurve is still _drawn_ entirely within the canvas bounds:

<img alt="Demo of wall off-by-one error" src="recordings/wall-off-by-one-error.png" width="840" />

See [`wall-off-by-one-error.mp4`] for the full round from which the animated image above was extracted.

Our clone has replicated this quirk since [#263]; see that PR for details.

<details>

<summary>ℹ️ How to reproduce</summary>

  1. Checkout 44b15998c5aa709cd0dcbab2fbd031a9fea5e40b.

  1. Define this scenario in `TheScenario.elm`:

     ```elm
     theScenario : Scenario
     theScenario =
         [ ( Red
           , { x = 50
             , y = 3
             , direction = pi / 2 + 0.01
             }
           )
         , ( Green
           , { x = 50
             , y = 100
             , direction = pi / 2
             }
           )
         ]
     ```

  1. Stage the scenario:

     ```bash
     BASE_ADDRESS=0x7fff… # See "Finding addresses" above. We've seen 0x7fffc1c65ff6 and 0x7fffac604ff6 work in WSL; and 0x7fffd8010ff6 in native Linux.
     ./tools/scenario.py docs/original-game/ZATACKA.EXE ${BASE_ADDRESS:?} tools/dosbox-wsl.conf
     ```

</details>

[oldgames]: https://www.oldgames.sk/en/game/achtung-die-kurve
[disable ASLR]: https://askubuntu.com/questions/318315/how-can-i-temporarily-disable-aslr-address-space-layout-randomization/318476#318476
[DOSBox]: https://www.dosbox.com/index.php
[scanmem]: https://github.com/scanmem/scanmem
[#93]: https://github.com/SimonAlling/kurve/issues/93
[#164]: https://github.com/SimonAlling/kurve/pull/164
[#165]: https://github.com/SimonAlling/kurve/pull/165
[#170]: https://github.com/SimonAlling/kurve/pull/170
[#183]: https://github.com/SimonAlling/kurve/pull/183
[#187]: https://github.com/SimonAlling/kurve/pull/187
[#211]: https://github.com/SimonAlling/kurve/pull/211
[#216]: https://github.com/SimonAlling/kurve/pull/216
[#223]: https://github.com/SimonAlling/kurve/pull/223
[#231]: https://github.com/SimonAlling/kurve/pull/231
[#237]: https://github.com/SimonAlling/kurve/pull/237
[Brage Salhus Bunk]: https://github.com/Titanothere
[a theoretical "perfect overpainting"]: https://www.youtube.com/watch?v=6O6PUdb5_Jo
[proved]: https://github.com/SimonAlling/kurve/issues/93#issuecomment-3463651308
[`perfect-overpainting.mp4`]: recordings/perfect-overpainting.mp4
[#263]: https://github.com/SimonAlling/kurve/pull/263
[`wall-off-by-one-error.mp4`]: recordings/wall-off-by-one-error.mp4
