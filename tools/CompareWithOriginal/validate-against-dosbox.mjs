#!/usr/bin/env node
// Validates the original-game harness against the real ZATACKA.EXE running in DOSBox.
// See README.md in this directory.
//
// DOSBox runs headless as a child process of this script, which lets us read and write its emulated RAM via /proc/PID/mem (no sudo needed).
// We "press" buttons by writing directly to the game's key variables (key_space, keyL, keyR), which is what its keyboard interrupt handler would do.
// We record what happens by sampling x, y and dir. Then we replay the same inputs in the harness and check that it produces exactly the same values.

import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { parseArgs } from "node:util";
import { BUILD_DIR, DEFAULT_DECOMP_DIR, REPO_ROOT, buildHarness, fail, harnessPath, runOriginal } from "./original.mjs";

const USAGE = `Usage: node tools/CompareWithOriginal/validate-against-dosbox.mjs [options]

Options:
  --game DIR          Directory with ZATACKA.EXE, EGAVGA.BGI and TSCR.CHR (default: docs/original-game)
  --decomp DIR        Path to zatacka-decomp (default: the zatacka-decomp submodule)
  --players LIST      Comma-separated player IDs; not Blue (default: 0,1,2)
  --seconds N         How long to let the game run (default: 40)
  --steering on|off   Whether to steer randomly (default: on)
  --no-build          Don't (re)build the harness
  --help`;

// Offsets into the game's data segment (DGROUP), from the comments in zatacka.cpp:
const DS = {
    palette: 0x00aa,
    key_space: 0x0ec0,
    joined: 0x0f0e,
    score: 0x0f02,
    dead: 0x0f26,
    keyL: 0x0f32,
    keyR: 0x0f3c,
    x: 0x0f66,
    y: 0x0f7e,
    dir: 0x0f96,
};
const SAMPLED_FROM = DS.score;
const SAMPLED_TO = DS.dir + 6 * 4;

// int palette[16][3] at DS:00AA is a recognizable byte sequence that tells us where DS is.
const PALETTE_SIGNATURE = Buffer.from(
    new Int16Array([0, 0, 0, 8, 8, 8, 12, 12, 12, 16, 16, 16, 20, 20, 20, 24, 24, 24, 28, 28, 28, 32, 32, 32, 63, 10, 0, 48, 48, 0]).buffer,
);
const BIOS_DATE = Buffer.from("01/01/92"); // DOSBox's hardcoded BIOS date …
const GUEST_ADDRESS_OF_BIOS_DATE = 0xffff5; // … which, like a real PC BIOS, it puts here.
const CONVENTIONAL_MEMORY_SIZE = 0xa0000;
// A tick takes at least 12 ms (with 6 players alive), almost all of which is spent in delay().
// Anything that's stable for this long is (almost certainly) the state between two ticks, not a state in the middle of a tick.
const STABLE_FOR_MS = 7;

async function main() {
    const { values: options } = parseArgs({
        options: {
            game: { type: "string", default: path.join(REPO_ROOT, "docs", "original-game") },
            decomp: { type: "string", default: DEFAULT_DECOMP_DIR },
            players: { type: "string", default: "0,1,2" },
            seconds: { type: "string", default: "40" },
            steering: { type: "string", default: "on" },
            "no-build": { type: "boolean", default: false },
            help: { type: "boolean", default: false },
        },
    });
    if (options.help) {
        console.log(USAGE);
        return;
    }
    const players = options.players.split(",").map(Number).sort((a, b) => a - b);
    if (players.includes(5)) fail("Blue (mouse) is not supported.");

    if (!options["no-build"]) buildHarness(options.decomp, "float");

    console.log(`🚀 Running ${path.join(options.game, "ZATACKA.EXE")} in headless DOSBox for ${options.seconds} seconds …`);
    const samples = await recordDosbox(options.game, players, Number(options.seconds) * 1000, options.steering === "on");

    const { rounds, presses, ambiguities } = reconstruct(samples, players);
    console.log(`📼 Observed ${rounds.length} rounds (${rounds.map((r) => r.lastTick).join(", ")} ticks), ${presses.length} ticks with buttons held, ${ambiguities.length} ambiguities.`);
    if (rounds.length === 0) fail("No rounds observed.");

    const replayFile = path.join(BUILD_DIR, "dosbox-replay.txt");
    fs.writeFileSync(replayFile, presses.map((p) => `${p.round} ${p.tick} ${p.id} ${p.button}\n`).join(""));
    const harnessRounds = runOriginal(harnessPath("float"), {
        players,
        rounds: String(rounds.length),
        seed: "1",
        botSeed: "1",
        holes: true,
        maxTicks: "100000",
        steering: `replay:${replayFile}`,
    });

    let checked = 0;
    const mismatches = [];
    for (const round of rounds) {
        const harnessRound = harnessRounds[round.round - 1];
        const validUntil = Math.min(round.lastTick, ...ambiguities.filter((a) => a.round === round.round).map((a) => a.tick - 1));
        for (const observation of round.observations) {
            if (observation.tick > validUntil) continue;
            const record = observation.tick === 0 ? harnessRound.start : harnessRound.ticks[observation.tick - 1];
            const expected = record?.players.find((p) => p.id === observation.id);
            checked++;
            const same =
                expected !== undefined && expected.x === observation.x && expected.y === observation.y && (observation.dir === null || expected.dir === observation.dir);
            if (!same) mismatches.push({ round: round.round, ...observation, expected });
        }
    }

    console.log(`🔍 Compared ${checked} observed player states with the harness.`);
    if (mismatches.length === 0) {
        console.log("✅ The harness matches the real game exactly.");
    } else {
        console.log(`❌ ${mismatches.length} mismatches. First few:`);
        for (const m of mismatches.slice(0, 5)) {
            console.log(`  round ${m.round} tick ${m.tick} player ${m.id}: DOSBox x=${m.x} y=${m.y} dir=${m.dir}; harness ${m.expected === undefined ? "nothing" : `x=${m.expected.x} y=${m.expected.y} dir=${m.expected.dir}`}`);
        }
        process.exitCode = 1;
    }
}

// ---- Recording ----

async function recordDosbox(gameDir, players, durationMs, steer) {
    fs.mkdirSync(BUILD_DIR, { recursive: true });
    const conf = path.join(BUILD_DIR, "dosbox-validate.conf");
    fs.writeFileSync(
        conf,
        [
            "[cpu]",
            "cycles=max", // so that the game logic in each tick runs in (practically) no time, and the game spends its time in delay()
            "[mixer]",
            "nosound=true",
            "[autoexec]",
            `mount c "${path.resolve(gameDir)}"`,
            "c:",
            "ZATACKA.EXE",
            "",
        ].join("\n"),
    );
    const dosbox = spawn("dosbox", ["-conf", conf], {
        env: { ...process.env, SDL_VIDEODRIVER: "dummy", SDL_AUDIODRIVER: "dummy" },
        stdio: "ignore",
    });
    const cleanUp = () => dosbox.kill("SIGKILL");
    process.on("exit", cleanUp);

    try {
        await sleep(1500);
        const memFd = fs.openSync(`/proc/${dosbox.pid}/mem`, "r+");
        const guestRam = findGuestRam(dosbox.pid, memFd);
        const dsBase = await waitFor(() => findDataSegment(memFd, guestRam), 10000, "the game's data segment");
        const read = (offset, length) => {
            const buffer = Buffer.alloc(length);
            fs.readSync(memFd, buffer, 0, length, dsBase + offset);
            return buffer;
        };
        const writeInt = (offset, value) => {
            const buffer = Buffer.alloc(2);
            buffer.writeInt16LE(value);
            fs.writeSync(memFd, buffer, 0, 2, dsBase + offset);
        };

        // Join and start:
        writeInt(DS.key_space, 1);
        for (const id of players) writeInt(DS.keyL + 2 * id, 1);
        await waitFor(() => players.every((id) => read(DS.joined + 2 * id, 2).readInt16LE() === 1) || null, 5000, "players to join");
        for (const id of players) writeInt(DS.keyL + 2 * id, 0);

        // Sample until time is up (or the game is over), steering randomly:
        const scoreToWin = (players.length - 1) * 10;
        const samples = [];
        const start = Date.now();
        let candidate = null;
        let candidateSince = 0;
        let nextSteeringChange = start;
        let firstSpawnPosition = null; // non-null while we're waiting for the first tick of a round
        while (Date.now() - start < durationMs) {
            const now = Date.now();
            const block = read(SAMPLED_FROM, SAMPLED_TO - SAMPLED_FROM);
            if (candidate === null || !block.equals(candidate)) {
                candidate = block;
                candidateSince = now;
            } else if (now - candidateSince >= STABLE_FOR_MS && (samples.length === 0 || !samples[samples.length - 1].equals(block))) {
                const sample = parseSample(block, players);
                if (sample.some((p) => p.score >= scoreToWin)) {
                    // The game will go back to the splash screen and lobby, and we don't want to go there.
                    // (The harness never gets there because it resets the scores in each round.)
                    break;
                }
                if (firstSpawnPosition === null && samples.length > 0 && someoneSpawned(samples[samples.length - 1], sample)) {
                    // Each player's direction is set after its spawn flickering, so the direction "before the first tick" can't be observed.
                    // We keep the buttons released until the first tick, so that we know that nobody turned in it.
                    for (const id of players) {
                        writeInt(DS.keyL + 2 * id, 0);
                        writeInt(DS.keyR + 2 * id, 0);
                    }
                    firstSpawnPosition = sample[0];
                } else if (firstSpawnPosition !== null && (sample[0].x !== firstSpawnPosition.x || sample[0].y !== firstSpawnPosition.y)) {
                    // The first player to spawn has moved, so everyone has spawned and the first tick is over.
                    firstSpawnPosition = null;
                }
                samples.push(block);
            }
            if (steer && now >= nextSteeringChange && firstSpawnPosition === null) {
                const id = players[Math.floor(Math.random() * players.length)];
                const r = Math.random();
                writeInt(DS.keyL + 2 * id, r < 0.3 ? 1 : 0);
                writeInt(DS.keyR + 2 * id, r >= 0.3 && r < 0.6 ? 1 : 0);
                nextSteeringChange = now + 100 + Math.random() * 500;
            }
            await sleep(1);
        }
        return samples.map((block) => parseSample(block, players));
    } finally {
        cleanUp();
    }
}

function someoneSpawned(before, after) {
    const b = parseSample(before, after.map((p) => p.id));
    return after.some((a, i) => Math.hypot(a.x - b[i].x, a.y - b[i].y) > 3);
}

function parseSample(block, players) {
    const int = (offset) => block.readInt16LE(offset - SAMPLED_FROM);
    const float = (offset) => block.readFloatLE(offset - SAMPLED_FROM);
    return players.map((id) => ({
        id,
        x: float(DS.x + 4 * id),
        y: float(DS.y + 4 * id),
        dir: float(DS.dir + 4 * id),
        dead: int(DS.dead + 2 * id) !== 0,
        score: int(DS.score + 2 * id),
    }));
}

function findGuestRam(pid, memFd) {
    for (const line of fs.readFileSync(`/proc/${pid}/maps`, "utf-8").split("\n")) {
        const [range, permissions] = line.split(" ");
        if (permissions === undefined || !permissions.startsWith("rw")) continue;
        const [start, end] = range.split("-").map((hex) => Number.parseInt(hex, 16));
        if (end - start < GUEST_ADDRESS_OF_BIOS_DATE || end - start > 1 << 28) continue;
        const region = Buffer.alloc(end - start);
        try {
            fs.readSync(memFd, region, 0, region.length, start);
        } catch {
            continue;
        }
        const offset = region.indexOf(BIOS_DATE);
        if (offset !== -1) return start + offset - GUEST_ADDRESS_OF_BIOS_DATE;
    }
    fail("Couldn't find DOSBox's emulated RAM.");
}

function findDataSegment(memFd, guestRam) {
    const conventionalMemory = Buffer.alloc(CONVENTIONAL_MEMORY_SIZE);
    fs.readSync(memFd, conventionalMemory, 0, conventionalMemory.length, guestRam);
    const offset = conventionalMemory.indexOf(PALETTE_SIGNATURE);
    return offset === -1 ? null : guestRam + offset - DS.palette;
}

// ---- Reconstructing ticks and inputs ----

/**
 * Figures out which tick each sample belongs to (each player moves exactly 1 pixel per tick), and what buttons were held in each tick (from how dir changed).
 */
function reconstruct(samples, players) {
    const TURN_RATE = 0.035;
    const rounds = [];
    const presses = [];
    const ambiguities = [];
    for (const id of players) {
        let round = 0;
        let tick = 0;
        let previous = null;
        for (const sample of samples) {
            const s = sample.find((p) => p.id === id);
            if (previous !== null && s.x === previous.x && s.y === previous.y && s.dir === previous.dir) continue;
            const distance = previous === null ? Infinity : Math.hypot(s.x - previous.x, s.y - previous.y);
            if (distance > 3) {
                // Spawned in a new round.
                if (s.x === 0 && s.y === 0) continue; // not spawned yet
                round++;
                tick = 0;
                rounds[round - 1] ??= { round, observations: [], lastTick: 0 };
                rounds[round - 1].observations.push({ id, tick, x: s.x, y: s.y, dir: null }); // dir is not set yet when the player appears
                previous = { ...s, dir: null };
                continue;
            } else if (previous.dead) {
                continue;
            } else {
                const ticks = Math.round(distance);
                if (ticks === 0) {
                    // Only dir changed, which can happen after the round has ended.
                    continue;
                }
                // Nobody turns in the first tick (see recordDosbox).
                // If we missed some ticks, we only see their net turn, so e.g. L then R looks like no turn at all and isn't flagged as ambiguous.
                // That makes the replay go straight where the real game didn't, which shows up as a mismatch (a false match would require ending up in exactly the same float position).
                const turns = previous.dir === null ? 0 : Math.round((s.dir - previous.dir) / TURN_RATE);
                const button = turns > 0 ? "L" : "R";
                if (turns !== 0 && Math.abs(turns) !== ticks) {
                    ambiguities.push({ round, tick: tick + 1, id });
                }
                for (let i = 1; i <= ticks; i++) {
                    if (turns !== 0) presses.push({ round, tick: tick + i, id, button });
                }
                tick += ticks;
            }
            rounds[round - 1].observations.push({ id, tick, x: s.x, y: s.y, dir: s.dir });
            rounds[round - 1].lastTick = Math.max(rounds[round - 1].lastTick, tick);
            previous = s;
        }
    }
    return { rounds, presses, ambiguities };
}

// ---- Utilities ----

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitFor(f, timeoutMs, what) {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
        const result = f();
        if (result !== null) return result;
        await sleep(10);
    }
    fail(`Timed out waiting for ${what}.`);
}

await main();
