#!/usr/bin/env node
// Plays rounds in the original game (natively compiled reconstructed source code) and replays them in the clone, then compares how they played out.
// See README.md in this directory.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { parseArgs } from "node:util";
import { BUILD_DIR, DEFAULT_DECOMP_DIR, REPO_ROOT, buildHarness, fail, harnessPath, requireBuilt, runOriginal } from "./original.mjs";

const CANVAS_WIDTH = 559;
const CANVAS_HEIGHT = 480;
const PLAYER_NAMES = ["Red", "Yellow", "Orange", "Green", "Pink", "Blue"];
const PLAYER_IDS_BY_NAME = Object.fromEntries(PLAYER_NAMES.map((name, id) => [name.toLowerCase(), id]));

const USAGE = `Usage: node tools/CompareWithOriginal/compare.mjs [options]

Options:
  --decomp DIR        Path to zatacka-decomp (default: the zatacka-decomp submodule)
  --players LIST      Comma-separated player names or IDs (default: red,yellow,orange,green,pink,blue)
  --seeds RANGE       Seeds for the original game's RNG, e.g. 1 or 1-50 (default: 1). Seed 1 is what the original actually uses.
  --rounds N          Rounds per seed (default: 1)
  --bot-seed N        Seed for the bots' RNG (default: same as --seeds)
  --holes on|off      (default: on)
  --float-model M     "float" (like the original) or "double" (like the clone) for positions and directions in the original (default: float)
  --max-ticks N       After this many ticks, bots stop steering (default: 20000)
  --what-if-original-order
                      Make the clone process the Kurves in the same order as the original (Red first) instead of Blue first
  --verbose           Show details about every divergence
  --json FILE         Also write all results as JSON to FILE
  --no-build          Don't (re)build anything
  --help`;

async function main() {
    const { values: options } = parseArgs({
        options: {
            decomp: { type: "string", default: DEFAULT_DECOMP_DIR },
            players: { type: "string", default: PLAYER_NAMES.join(",").toLowerCase() },
            seeds: { type: "string", default: "1" },
            rounds: { type: "string", default: "1" },
            "bot-seed": { type: "string" },
            holes: { type: "string", default: "on" },
            "float-model": { type: "string", default: "float" },
            "max-ticks": { type: "string", default: "20000" },
            "what-if-original-order": { type: "boolean", default: false },
            verbose: { type: "boolean", default: false },
            json: { type: "string" },
            "no-build": { type: "boolean", default: false },
            help: { type: "boolean", default: false },
        },
    });

    if (options.help) {
        console.log(USAGE);
        return;
    }

    const players = options.players.split(",").map(parsePlayer).sort((a, b) => a - b); // The clone keeps its Kurves sorted by ID too.
    if (new Set(players).size !== players.length) fail(`Duplicate player in: ${options.players}`);
    if (players.length < 2) fail("At least 2 players are needed.");
    const seeds = parseRange(options.seeds);
    requireInt(options.rounds, "--rounds", 1);
    requireInt(options["max-ticks"], "--max-ticks", 0);
    if (options["bot-seed"] !== undefined) requireInt(options["bot-seed"], "--bot-seed", 0);
    if (!["on", "off"].includes(options.holes)) fail(`--holes must be "on" or "off", not "${options.holes}".`);
    const holes = options.holes === "on";
    const floatModel = options["float-model"];
    if (!["float", "double"].includes(floatModel)) fail(`Unknown float model: ${floatModel}`);

    const harness = harnessPath(floatModel);
    const cloneSimulationJs = path.join(BUILD_DIR, "CloneSimulation.js");
    if (!options["no-build"]) {
        buildHarness(options.decomp, floatModel);
        buildCloneSimulation();
    }
    requireBuilt(cloneSimulationJs);
    const { Elm } = createRequire(import.meta.url)(cloneSimulationJs);

    const cloneOptions = { holes, whatIfOriginalOrder: options["what-if-original-order"] };
    const results = [];
    for (const seed of seeds) {
        const botSeed = options["bot-seed"] ?? String(seed);
        const rounds = runOriginal(harness, {
            players,
            rounds: options.rounds,
            seed: String(seed),
            botSeed,
            holes,
            maxTicks: options["max-ticks"],
        });
        for (const round of rounds) {
            const scenario = cloneScenarioFrom(round, cloneOptions);
            const clone = await runClone(Elm, scenario);
            const result = { seed, botSeed: Number(botSeed), ...compareRound(round, clone, scenario) };
            results.push(result);
            printResult(result, options.verbose);
            if (options.verbose && !["identical", "equivalent"].includes(result.verdict)) {
                await printSurroundings(result, cloneOptions, { harness, Elm, players, rounds: options.rounds, seed: String(seed), botSeed, holes, maxTicks: options["max-ticks"] });
            }
        }
    }

    printSummary(results);
    if (options.json !== undefined) {
        fs.writeFileSync(options.json, JSON.stringify(results, null, 2));
        console.log(`\nWrote ${options.json}`);
    }
}

// ---- Building ----

// Builds CloneSimulation.js in BUILD_DIR (as specified in package.json).
function buildCloneSimulation() {
    execFileSync("npm", ["run", "--silent", "build:compare-with-original"], {
        cwd: REPO_ROOT,
        stdio: ["ignore", "ignore", "inherit"],
    });
}

/**
 * Translates what happened in the original game into a scenario for the clone.
 */
function cloneScenarioFrom(round, { holes, whatIfOriginalOrder }, dumpTicks = []) {
    const { start, ticks } = round;
    return {
        maxTicks: ticks.length + 10,
        dumpTicks,
        whatIfOriginalOrder,
        kurves: start.players.map((player, i) => ({
            id: player.id,
            x: player.x,
            y: player.y,
            direction: player.dir,
            turning: turningFor(player.id, ticks),
            solidity: holes ? solidityFor(player.id, start, ticks, start.spawnErasedInFirstTick[i]) : ALWAYS_SOLID,
        })),
    };
}

/**
 * The original samples the buttons _after_ moving, so the buttons in tick N affect the direction in tick N + 1 (see README.md#input-delay).
 * The clone applies the turning state of tick N before moving in tick N.
 */
function turningFor(id, ticks) {
    const result = [];
    let previous = "none";
    for (const record of ticks) {
        const input = record.inputs.find((i) => i.id === id);
        const turning = input.left && !input.right ? "left" : input.right && !input.left ? "right" : "none";
        if (turning !== previous) result.push([record.tick + 1, turning]);
        previous = turning;
    }
    return result;
}

/**
 * Whether the Kurve leaves a permanent mark in each tick (0 = the spawn position), as seen from the original's perspective:
 *
 *   - Solid branch: drawn permanently.
 *   - Hole branch: drawn temporarily; erased in the next tick unless that tick is a solid one.
 *     The hole branch with countdown 0 is always followed by a solid tick, so it's effectively solid.
 * See README.md#hole-mapping.
 */
function solidityFor(id, start, ticks, spawnErasedInFirstTick) {
    const solidity = [!spawnErasedInFirstTick];
    let before = start.players.find((p) => p.id === id);
    for (const record of ticks) {
        const solidBranch = before.countdown > before.holeTicks;
        solidity.push(solidBranch || before.countdown === 0);
        before = record.players.find((p) => p.id === id);
    }
    return solidity;
}

// A solidity array is non-empty; its last value applies to all later ticks.
const ALWAYS_SOLID = [true];

function solidIn(solidity, tick) {
    if (solidity.length === 0) throw new Error("solidity must be non-empty");
    return solidity[Math.min(tick, solidity.length - 1)];
}

function runClone(Elm, scenario) {
    return new Promise((resolve) => {
        const app = Elm.CloneSimulation.init({ flags: scenario });
        app.ports.outputPort.subscribe((output) => {
            const parsed = JSON.parse(output);
            if (parsed.error !== undefined) fail(`CloneSimulation failed: ${parsed.error}`);
            resolve(parsed);
        });
    });
}

// ---- Comparing ----

function compareRound(round, clone, scenario) {
    const { start, ticks, end } = round;
    const ids = start.players.map((p) => p.id);
    const originalEndTick = end.tick;
    const cloneEndTick = clone.endTick;

    const divergences = [];
    const maxDrift = Object.fromEntries(ids.map((id) => [id, 0]));
    let firstDivergenceTick = null;
    let unprocessedInFinalTick = [];

    const lastTick = Math.min(originalEndTick, cloneEndTick);
    for (let t = 1; t <= lastTick; t++) {
        const originalRecord = ticks[t - 1];
        const previousOriginalRecord = t === 1 ? start : ticks[t - 2];
        const cloneRecord = clone.ticks[t - 1];
        for (const id of ids) {
            const o = originalRecord.players.find((p) => p.id === id);
            const oBefore = previousOriginalRecord.players.find((p) => p.id === id);
            const c = cloneRecord.find((k) => k.id === id);
            if (oBefore.dead) continue; // Already dead in the original; nothing more to compare.

            // When a Kurve dies and only one remains, the original ends the round immediately, so the remaining Kurves don't move in that tick.
            const originalDidNotMove = t === originalEndTick && !o.dead && o.x === oBefore.x && o.y === oBefore.y;
            if (originalDidNotMove) {
                unprocessedInFinalTick.push(id);
                continue;
            }

            if (!o.dead && !c.dead) {
                maxDrift[id] = Math.max(maxDrift[id], Math.abs(o.x - c.x), Math.abs(o.y - c.y));
            }

            const cPx = Math.trunc(c.x);
            const cPy = Math.trunc(c.y);
            // A dead Kurve's x/y is where it tried to go.
            const oPx = Math.trunc(o.x);
            const oPy = Math.trunc(o.y);

            let kind = null;
            if (o.dead !== c.dead) kind = o.dead ? "diesOnlyInOriginal" : "diesOnlyInClone";
            else if (oPx !== cPx || oPy !== cPy) kind = "differentPosition";

            if (kind !== null) {
                divergences.push({
                    tick: t,
                    id,
                    player: PLAYER_NAMES[id],
                    kind,
                    // The original's dir has already been updated for the next tick at this point.
                    original: { x: o.x, y: o.y, dir: oBefore.dir, pixel: [oPx, oPy], dead: o.dead },
                    clone: { x: c.x, y: c.y, dir: c.dir, pixel: [cPx, cPy], dead: c.dead },
                    driftSoFar: maxDrift[id],
                });
                firstDivergenceTick ??= t;
            }
        }
        if (firstDivergenceTick !== null) break;
    }

    const originalSurvivors = end.players.filter((p) => !p.dead).map((p) => p.id);
    const finalClone = clone.ticks[clone.ticks.length - 1];
    const cloneSurvivors = finalClone.filter((k) => !k.dead).map((k) => k.id);

    let canvasDiff = null;
    if (firstDivergenceTick === null && originalEndTick === cloneEndTick) {
        // Known, explainable differences in the final canvas:
        const lastTickMovedInOriginal = (id) => (unprocessedInFinalTick.includes(id) ? originalEndTick - 1 : originalEndTick);
        const holyHeadsInOriginal = scenario.kurves
            .filter((k) => !solidIn(k.solidity, lastTickMovedInOriginal(k.id)))
            .map((k) => end.players.find((p) => p.id === k.id))
            .map((p) => [p.px, p.py]);
        const movedOnlyInClone = unprocessedInFinalTick
            .map((id) => finalClone.find((k) => k.id === id))
            .map((k) => [Math.trunc(k.x), Math.trunc(k.y)]);
        const staleBackgroundsInOriginal = start.players.filter((_, i) => start.spawnErasedInFirstTick[i]).map((p) => [p.px, p.py]);
        canvasDiff = compareCanvases(end.canvas, clone.canvas, { holyHeadsInOriginal, movedOnlyInClone, staleBackgroundsInOriginal });
    }

    let verdict;
    if (firstDivergenceTick !== null) verdict = "diverged";
    else if (originalEndTick !== cloneEndTick) verdict = "differentEndTick";
    else if (originalSurvivors.join() !== cloneSurvivors.join()) verdict = "differentSurvivors"; // e.g. the clone moved a Kurve that the original didn't move in the final tick, and it died (README.md#round-ends-mid-tick)
    else if (canvasDiff.onlyInOriginal.length + canvasDiff.onlyInClone.length > 0) verdict = "differentCanvas";
    else if (canvasDiff.explainedOnlyInOriginal + canvasDiff.explainedOnlyInClone > 0) verdict = "equivalent";
    else verdict = "identical";

    return {
        round: round.round,
        players: ids,
        verdict,
        originalEndTick,
        cloneEndTick,
        originalSurvivors,
        cloneSurvivors,
        firstDivergenceTick,
        divergences,
        maxDrift,
        unprocessedInFinalTick,
        canvasDiff,
    };
}

function decodeCanvas(runs) {
    const pixels = new Uint8Array(CANVAS_WIDTH * CANVAS_HEIGHT);
    let i = 0;
    let value = 0;
    for (const run of runs) {
        pixels.fill(value, i, i + run);
        i += run;
        value = 1 - value;
    }
    if (i !== pixels.length) fail(`Canvas has ${i} pixels; expected ${pixels.length}.`);
    return pixels;
}

/**
 * Pixels that are only in one of the canvases, except those that are explained by known differences:
 *
 *   - Holy heads: The original always has every head on screen, holy or not. The clone doesn't consider holy heads occupied (README.md#holy-heads).
 *   - When the round ends, the original doesn't move the Kurves after the one whose death ended the round. The clone does (README.md#round-ends-mid-tick).
 *   - A Kurve that starts a round in a hole "erases" its spawn square in the original by restoring the background it saved last, which is from the previous round (README.md#stale-spawn-background).
 */
function compareCanvases(originalRuns, cloneRuns, { holyHeadsInOriginal, movedOnlyInClone, staleBackgroundsInOriginal }) {
    const original = decodeCanvas(originalRuns);
    const clone = decodeCanvas(cloneRuns);
    const isInSquare = ([x, y]) => ([left, top]) => x >= left && x <= left + 2 && y >= top && y <= top + 2;
    const onlyInOriginal = [];
    const onlyInClone = [];
    let explainedOnlyInOriginal = 0;
    let explainedOnlyInClone = 0;
    for (let i = 0; i < original.length; i++) {
        const pixel = [i % CANVAS_WIDTH, Math.floor(i / CANVAS_WIDTH)];
        if (original[i] && !clone[i]) {
            if ([...holyHeadsInOriginal, ...staleBackgroundsInOriginal].some(isInSquare(pixel))) explainedOnlyInOriginal++;
            else onlyInOriginal.push(pixel);
        }
        if (clone[i] && !original[i]) {
            if (movedOnlyInClone.some(isInSquare(pixel))) explainedOnlyInClone++;
            else onlyInClone.push(pixel);
        }
    }
    return { onlyInOriginal, onlyInClone, explainedOnlyInOriginal, explainedOnlyInClone };
}

// ---- Reporting ----

function printResult(r, verbose) {
    const names = (ids) => ids.map((id) => PLAYER_NAMES[id]).join("+") || "none";
    let line = `seed ${r.seed} round ${r.round}: ${r.verdict.padEnd(16)} ticks ${r.originalEndTick}/${r.cloneEndTick} (original/clone), survivors ${names(r.originalSurvivors)}/${names(r.cloneSurvivors)}`;
    if (r.firstDivergenceTick !== null) {
        const d = r.divergences[0];
        line += `; first divergence at tick ${d.tick}: ${d.player} ${d.kind}`;
    }
    if (r.canvasDiff !== null && r.verdict === "differentCanvas") {
        line += `; canvas: ${r.canvasDiff.onlyInOriginal.length} px only in original, ${r.canvasDiff.onlyInClone.length} px only in clone`;
    }
    console.log(line);
    if (verbose) {
        for (const d of r.divergences) {
            console.log(`    ${d.player} at tick ${d.tick}: ${d.kind}`);
            console.log(`      original: ${fmt(d.original)}`);
            console.log(`      clone:    ${fmt(d.clone)}`);
            console.log(`      max position difference before this: ${d.driftSoFar.toExponential(2)}`);
        }
        if (r.canvasDiff !== null) {
            const sample = (pixels) => pixels.slice(0, 12).map(([x, y]) => `(${x},${y})`).join(" ") + (pixels.length > 12 ? " …" : "");
            if (r.canvasDiff.onlyInOriginal.length > 0) console.log(`    only in original: ${sample(r.canvasDiff.onlyInOriginal)}`);
            if (r.canvasDiff.onlyInClone.length > 0) console.log(`    only in clone:    ${sample(r.canvasDiff.onlyInClone)}`);
        }
        if (r.unprocessedInFinalTick.length > 0) {
            console.log(`    not moved by the original in the final tick: ${names(r.unprocessedInFinalTick)}`);
        }
    }
}

/**
 * Shows the canvas in both games around where the first difference occurred, before and after the tick in question.
 */
async function printSurroundings(result, cloneOptions, { harness, Elm, ...originalOptions }) {
    let tick, center;
    if (result.divergences.length > 0) {
        const d = result.divergences[0];
        tick = d.tick;
        center = d.original.pixel;
    } else if (result.canvasDiff !== null) {
        tick = result.originalEndTick;
        center = [...result.canvasDiff.onlyInOriginal, ...result.canvasDiff.onlyInClone][0] ?? null;
    } else {
        return;
    }
    const dumpTicks = [tick - 1, tick];
    const rounds = runOriginal(harness, { ...originalOptions, dumps: dumpTicks.map((t) => ({ round: result.round, tick: t })) });
    const round = rounds.find((r) => r.round === result.round);
    const clone = await runClone(Elm, cloneScenarioFrom(round, cloneOptions, dumpTicks));
    if (center === null) {
        // Same canvas, different survivors: center on a Kurve that survived in only one of the games.
        const id = [...result.originalSurvivors, ...result.cloneSurvivors].find((i) => !(result.originalSurvivors.includes(i) && result.cloneSurvivors.includes(i)));
        const kurve = clone.ticks[clone.ticks.length - 1].find((k) => k.id === id);
        center = [Math.trunc(kurve.x), Math.trunc(kurve.y)];
    }

    const RADIUS_X = 12;
    const RADIUS_Y = 7;
    const [cx, cy] = center;
    const xs = range(cx - RADIUS_X, cx + RADIUS_X);
    const ys = range(cy - RADIUS_Y, cy + RADIUS_Y);
    const originalChar = (pixels, x, y) => {
        if (x < 0 || y < 0 || x >= CANVAS_WIDTH || y >= CANVAS_HEIGHT) return " ";
        const color = parseInt(pixels[y * CANVAS_WIDTH + x], 16);
        return color === 0 ? "·" : color >= 8 && color <= 13 ? "RYOGPB"[color - 8] : "#";
    };
    const cloneChar = (pixels, x, y) => {
        if (x < 0 || y < 0 || x >= CANVAS_WIDTH || y >= CANVAS_HEIGHT) return " ";
        return pixels[y * CANVAS_WIDTH + x] ? "#" : "·";
    };
    const panels = [];
    for (const t of dumpTicks) {
        const pixels = round.dumps[t];
        panels.push({ title: `original after tick ${t}`, rows: ys.map((y) => xs.map((x) => originalChar(pixels, x, y)).join("")) });
    }
    for (const t of dumpTicks) {
        const pixels = decodeCanvas(clone.dumps.find((d) => d.tick === t).canvas);
        panels.push({ title: `clone after tick ${t}`, rows: ys.map((y) => xs.map((x) => cloneChar(pixels, x, y)).join("")) });
    }
    const width = xs.length + 3;
    console.log(`    canvas around (${cx},${cy}), x ${xs[0]}..${xs[xs.length - 1]}, y ${ys[0]}..${ys[ys.length - 1]}:`);
    console.log("    " + panels.map((p) => p.title.padEnd(width)).join(""));
    for (let i = 0; i < ys.length; i++) {
        console.log("    " + panels.map((p) => p.rows[i].padEnd(width)).join(""));
    }
}

function range(from, to) {
    return Array.from({ length: to - from + 1 }, (_, i) => from + i);
}

function fmt({ x, y, dir, pixel, dead }) {
    return `x=${x} y=${y} dir=${dir} pixel=(${pixel.join(",")})${dead ? " DEAD" : ""}`;
}

function printSummary(results) {
    const counts = {};
    for (const r of results) {
        const key = r.verdict === "diverged" ? `diverged (${r.divergences[0].kind})` : r.verdict;
        counts[key] = (counts[key] ?? 0) + 1;
    }
    console.log(`\nSummary of ${results.length} rounds:`);
    for (const [key, count] of Object.entries(counts).sort((a, b) => b[1] - a[1])) {
        console.log(`  ${String(count).padStart(5)}  ${key}`);
    }
}

// ---- Utilities ----

function requireInt(s, name, min) {
    if (!/^\d+$/.test(s) || Number(s) < min) fail(`${name} must be an integer ≥ ${min}, not "${s}".`);
}

function parsePlayer(s) {
    const id = /^\d$/.test(s) ? Number(s) : PLAYER_IDS_BY_NAME[s.toLowerCase()];
    if (id === undefined || id < 0 || id > 5) fail(`Unknown player: ${s}`);
    return id;
}

function parseRange(s) {
    const match = /^(\d+)(?:-(\d+))?$/.exec(s);
    if (match === null) fail(`Invalid range: ${s}`);
    const from = Number(match[1]);
    const to = match[2] === undefined ? from : Number(match[2]);
    if (to < from) fail(`Invalid range: ${s} (end is before start)`);
    return Array.from({ length: to - from + 1 }, (_, i) => from + i);
}

await main();
