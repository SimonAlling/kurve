# Comparing the clone with the original game

This directory contains tooling for **automated, tick-by-tick comparison of how rounds play out** in the original game and in our clone.

```bash
# 100 seeds × 2 rounds with all six players, steered by bots:
npm run compare-with-original -- --seeds 1-100 --rounds 2

# Same, but with the float32 issue (see below) taken out of the equation, and details about every difference:
npm run compare-with-original -- --seeds 1-100 --rounds 2 --float-model double --verbose

# Check that the native build of the original behaves exactly like the real ZATACKA.EXE in DOSBox:
node tools/CompareWithOriginal/validate-against-dosbox.mjs
```

Requirements: `g++` (x86-64), Node, Elm (`npm ci`), and the [zatacka-decomp] submodule (`git submodule update --init`).
The submodule pins the exact version of the decomp that the harness is known to work with; to try another version (e.g. a local working copy), pass `--decomp DIR`.
The DOSBox validation additionally requires DOSBox 0.74 (no window or `sudo` needed).

## How it works

```
                     ┌──────────────────────────────────────────┐
  seed, players ───▶ │ original-harness: zatacka.cpp compiled   │ ──▶ trace: spawn state, per-tick state of every
                     │ natively, with stand-ins for BGI and DOS │     Kurve, the buttons the bots held, final canvas
                     └──────────────────────────────────────────┘
                                                                       │
                     ┌──────────────────────────────────────────┐      ▼
                     │ CloneSimulation.elm: the clone's own     │ ◀── same spawn state, same inputs, same holes
                     │ Game.reactToTick                         │ ──▶ trace in the same format
                     └──────────────────────────────────────────┘
                                                                       │
                                                         compare.mjs ◀─┘ first divergence, final canvas, verdict
```

### The original: `original-harness/`

`harness.cpp` `#include`s the reconstructed source code of the original game and runs its `main()` **as is**.
The only changes to the game's code are mechanical:

  * `original.mjs` removes inline `asm` lines and renames `main`. With `--float-model double`, it also turns `x`, `y` and `dir` into `double`.
  * `harness.cpp` redefines a few names with macros before `#include`-ing the source code: `random` (Borland's, see below), `sin` and `cos` (extended precision, and `sin` detects the start of a round), and `malloc` as `calloc` (the game assumes that fresh heap memory is zeroed).

The game thinks it's talking to BGI and DOS, but it's talking to the stand-ins in `shim/` and `harness.cpp`:

  * BGI draws into an in-memory 640×480 framebuffer, and `getpixel` reads from it, so **collision detection is the game's own** (including all its quirks).
  * `random()` is Borland's (`seed × 0x015A4E35 + 1`, verified against the disassembly), unseeded like in the original. `--seed` lets us explore other RNG states.
  * Float math uses x87 extended precision (`-mfpmath=387 -fexcess-precision=standard`) like the original, with positions and directions stored as `float`.
  * The harness gets control in callbacks that the game makes anyway: the first `sin()` call in a round marks the round start, `delay(15 - alive_count / 2)` the end of a tick, and `delay(1000)` the end of a round.
  * Simple bots steer at the end of every tick, by simulating each option (left, right, straight) a bit into the future using the game's own collision logic on the framebuffer.
  * Scores are reset at the start of each round so that the game never ends.

<a id="clone-simulation"></a>
### The clone: `CloneSimulation.elm`

A `Platform.worker` that plays out the round using the clone's `Game.reactToTick`, given what the original decided:

  * **Spawn state:** the clone gets the original's spawn positions and directions (as floats; the original's directions are float32 values).
  * **Inputs:** the original reads the buttons _after_ moving, so buttons held in tick _N_ affect the direction in tick _N_ + 1. The clone applies the turning state of tick _N_ _before_ moving in tick _N_. So the original's buttons in tick _N_ become the clone's turning state in tick _N_ + 1.
  * **Holes:** before each tick, each Kurve's `HoleStatus` is overwritten so that it is holy exactly when the original's is (see [the hole mapping](#hole-mapping)).

### Comparing: `compare.mjs`

For every tick and Kurve: alive/dead and pixel position (`truncate` of x and y).
The first tick where anything differs is reported, because after that, the original's inputs make no sense for the clone anymore.
If no divergence occurs, the final canvases (obstacle pixels) are compared.

| Verdict              | Meaning                                                                                                    |
|----------------------|------------------------------------------------------------------------------------------------------------|
| `identical`          | Every tick and every pixel is the same.                                                                    |
| `equivalent`         | Like `identical`, except for known differences in the final canvas that can't affect gameplay (see below). |
| `differentCanvas`    | Same ticks, but some pixel differs at the end.                                                             |
| `differentSurvivors` | Same ticks, but different survivors (see [round end](#round-ends-mid-tick)).                               |
| `differentEndTick`   | No divergence, but the rounds ended in different ticks.                                                    |
| `diverged`           | A Kurve was in different pixels (`differentPosition`) or died in only one of the games (`diesOnlyIn…`).    |

With `--verbose`, the surroundings of the first difference are printed for both games, before and after the tick in question.

Options for isolating differences:

  * `--float-model double`: makes the original use double precision (like the clone) for positions and directions.
  * `--what-if-original-order`: makes the clone process the Kurves in the same order as the original.
  * `--holes off`: no holes in either game.

## Validation against DOSBox

Is the native build really the original? `validate-against-dosbox.mjs` runs the real `ZATACKA.EXE` in headless DOSBox and **presses buttons by writing to the game's `key_space`/`keyL`/`keyR` variables** in DOSBox's emulated RAM (via `/proc/PID/mem`, which works without `sudo` because DOSBox is our child process).
It steers randomly, samples `x`, `y` and `dir` of every player, figures out which tick each sample belongs to (Kurves move exactly 1 pixel per tick) and which buttons were held in each tick (from how `dir` changed), replays those inputs in the harness, and checks that **every observed float value is identical**.

Result: with 5 players, 19 rounds and ~5000 ticks with buttons held, all **16,071 observed player states matched exactly**, including spawn positions and directions in every round (Borland's RNG, hole re-rolls, collisions) and every float32 position.

<a id="findings"></a>
## Findings

Each section has an explicit anchor that doesn't depend on its heading. Code that handles a finding refers to it as `README.md#<anchor>`, so `git grep <anchor>` finds both the explanation and the code.

Rounds diverge mostly because of **float32 vs double**. With that taken out of the equation, **processing order** explains almost everything else.

| Configuration                                       | Rounds | Identical | Equivalent | Diverged / different                                                                                                              |
|-----------------------------------------------------|-------:|----------:|-----------:|-----------------------------------------------------------------------------------------------------------------------------------|
| 6 players (`--seeds 1-100 --rounds 2`)              |    200 |         1 |          0 | 199: 185 `differentPosition`, 11 `diesOnlyInClone`, 3 `diesOnlyInOriginal`                                                        |
| 2 players (`--players red,yellow`, same seeds)      |    200 |        20 |         32 | 148: 147 `differentPosition`, 1 `diesOnlyInClone`                                                                                 |
| 6 players, `--float-model double` (seeds 1–150)     |    300 |       124 |        138 | 38: 29 `diesOnlyInClone`, 8 `diesOnlyInOriginal`, 1 `differentSurvivors`                                                          |
| … and `--what-if-original-order`                    |    300 |       136 |        160 | 4: 2 `diesOnlyInOriginal` ([holy heads](#holy-heads)), 1 `differentSurvivors` ([round end](#round-ends-mid-tick)), 1 `differentCanvas` ([erased pixel](#holy-kurve-erases-pixels)) |

<a id="float32-precision"></a>
### Positions and directions are float32 in the original

The original stores `x`, `y` and `dir` as `float` (computing in x87 extended precision, then rounding on every store), while the clone uses `Float` (double).
The difference accumulates until a Kurve ends up in a different pixel than in the original.
With 6 players, the first divergence happens at tick 259 in the median case (10th percentile: 67, 90th: 550), whereas rounds last ~1300 ticks.
It's usually a 1-pixel difference that only rarely changes the outcome of the round; but when it does, it's essentially random.

```bash
npm run compare-with-original -- --players red,yellow --seeds 2 --rounds 2 --verbose
```

Making the clone round to float32 after every update of position and direction would fix this (see [Fixing float32 in the clone](#fixing-float32)).

<a id="processing-order"></a>
### The clone processes the Kurves in reverse order

In each tick, the original moves Red first and Blue last.
The clone's `reactToTick` uses `List.foldr` over the (ID-sorted) alive Kurves, so it moves **Blue first and Red last**.
This decides who survives when two Kurves move into the same pixels in the same tick: in the original, the _later_ Kurve dies, because the earlier one has already been drawn.
In the 300 rounds above, this caused 35 of 37 death-related divergences.

```bash
npm run compare-with-original -- --players red,yellow --seeds 25 --float-model double --verbose  # Red dies only in the clone
npm run compare-with-original -- --players red,yellow --seeds 25 --float-model double --what-if-original-order
```

<a id="holy-heads"></a>
### Holy heads are obstacles in the original

In the original, every head is always on screen, also in a hole; it's just erased when the Kurve moves on.
Since collision detection is `getpixel`, **you can crash into the head of a holy Kurve**.
In the clone, a holy Kurve occupies nothing.

```bash
npm run compare-with-original -- --seeds 10 --rounds 2 --float-model double --what-if-original-order --verbose  # Blue crashes into holy Orange
```

(At the end of a round, a holy head is also left on screen in the original. That's counted as `equivalent`.)

<a id="round-ends-mid-tick"></a>
### The original ends the round mid-tick

`move_or_die` ends the round **as soon as only one Kurve is alive**, so the Kurves after the one whose death ended the round don't move in that tick.
The clone moves all Kurves and then checks.
Consequences:

  * Usually just a 3×3 square drawn at the end of the round only in the clone (counted as `equivalent`).
  * The clone can end a round with **nobody alive** if the last two die in the same tick. That can't happen in the original: the survivor is decided by processing order.

```bash
npm run compare-with-original -- --seeds 22 --rounds 2 --float-model double --verbose  # Green survives only in the original
```

<a id="holy-kurve-erases-pixels"></a>
### A holy Kurve can erase other Kurves' pixels in the original

In a hole, the original saves the 3×3 background before drawing the head, and puts it back in the next tick.
If another Kurve paints there in between, that paint is erased when the background is restored.

```bash
npm run compare-with-original -- --seeds 123 --rounds 2 --float-model double --what-if-original-order --verbose  # Orange erases a Pink pixel
```

<a id="stale-spawn-background"></a>
### Leftovers from the previous round at spawn in the original

A Kurve that starts a round in a hole (hole status persists between rounds in the original) "erases" its spawn square by restoring the background it saved last, which is from the previous round.
That can resurrect bits of old trails:

```bash
npm run compare-with-original -- --players red,yellow --seeds 9 --rounds 3 --float-model double  # round 3: 2 Yellow pixels from round 2
```

This is counted as `equivalent` (it's a cosmetic difference, practically speaking), so `--verbose` doesn't show it; use `--dump 3:0` with the harness to see it.

<a id="input-delay"></a>
### The clone reacts one tick earlier

Because the original reads the buttons after moving, a button pressed between two ticks affects movement one tick later than in the clone (see [the clone](#clone-simulation)).
The comparison compensates for this, so it never shows up as a divergence. It's a difference in how the game _feels_, not in the simulation.

<a id="solid-segment-length"></a>
### Solid segments are 1 tick too short (sometimes) in the clone

Measured from the original (60 seeds × 3 rounds × 6 players): holy segments are 7–11 ticks, like in the clone.
Solid segments are **90–293** ticks, while the clone's `minSolidTicks` is 89.
Also, in the original, a solid segment is `countdown − hole_length + 1` with both uniformly distributed, so its length is not quite uniform (it tapers off at both ends), and a solid segment is slightly shorter when the following hole is longer.
This tool forces the original's holes onto the clone, so it doesn't detect this on its own.

<a id="black-pixel"></a>
### The "single black pixel" bug is practically invisible

zatacka.cpp documents that all Kurves except Red put a single black pixel at their spawn position in the first round.
The tool shows why nobody has noticed: the head drawn in the first tick covers that pixel, unless the spawn direction is exactly 0 or 1.5708 (2 of 31,415 possible directions).

<a id="open-questions"></a>
## Difficulties and open questions

<a id="hole-mapping"></a>
### Hole mapping

The clone's notion of holes (a Kurve is either solid or holy) doesn't directly match the original's (a hole branch that erases the previous head).
For the clone to be holy where the original is, we consider a Kurve solid in a tick if the original takes the solid branch **or** the hole branch with countdown 0 (whose head is never erased, because the next tick is solid).
The spawn square counts as solid unless the first tick restores a full 3×3 background over it.
[Holy heads](#holy-heads) and [erased pixels](#holy-kurve-erases-pixels) are not representable in the clone, so they show up as real differences, which is the point.

<a id="fixing-float32"></a>
### Fixing float32 in the clone

Elm has no `Math.fround`. Options include a round trip through `elm/bytes` (`Bytes.Encode.float32`) or a pure-Elm implementation.
Things to keep in mind:

  * The clone updates the direction _before_ moving, the original _after_; the rounding must happen on the stored values.
  * The original rounds once from extended precision; `fround(x + sin(dir))` in JavaScript rounds twice (to double, then to float). That only matters if the double result lies exactly halfway between two floats, which should be extraordinarily rare.
  * The original's `sin`/`cos` (Borland's RTL on the x87) and JavaScript's may differ in the last bit. The DOSBox validation found no difference between the harness (glibc's `sinl`) and the real game in ~16,000 states, but JavaScript's `Math.sin` is double precision only.

<a id="not-covered"></a>
### Things the comparison doesn't cover

  * **Time.** Everything is compared per tick. The original's tick takes `delay(15 - alive_count / 2)` ms (12–14 ms, so ~71–83 ticks per second plus computation time, getting slower as Kurves die), while the clone runs at a fixed 60 ticks per second. Is that intended (e.g. because the original runs slower on period hardware)?
  * **Spawning.** The clone gets the original's spawn positions, so differences in spawn distribution (the original's x range is 100–460, y 100–379, integers; spawnkill protection in the clone) aren't compared.
  * **Pressing both buttons.** In the original, `dir + 0.035 − 0.035` in float32 isn't necessarily `dir`. The bots never press both buttons.
  * **Bots are not humans.** They wander around and avoid obstacles. Deliberate behavior like tight spirals, wall hugging and squeezing through holes is probably underrepresented.
  * **Blue** is supported by the harness (mouse) but not by the DOSBox validation.
  * **Scores** are only compared indirectly, via survivors.

<a id="reproducibility"></a>
### Reproducibility

Everything is deterministic: the original game is unseeded, the bots have their own seeded RNG, and the clone simulation is pure.
The same command always gives the same result, as long as the decomp and the clone don't change.

[zatacka-decomp]: https://github.com/SimonAlling/zatacka-decomp
