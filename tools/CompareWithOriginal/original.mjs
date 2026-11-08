// Building and running the original game (natively compiled reconstructed source code) in original-harness/.

import { execFileSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname);
export const REPO_ROOT = path.resolve(HERE, "..", "..");
export const BUILD_DIR = path.join(HERE, ".build");
export const DEFAULT_DECOMP_DIR = path.join(REPO_ROOT, "tools", "CompareWithOriginal", "zatacka-decomp"); // Git submodule

export function requireBuilt(file) {
    if (!fs.existsSync(file)) fail(`Can't find ${file}. Run without --no-build to build it.`);
}

export function harnessPath(floatModel) {
    return path.join(BUILD_DIR, `harness-${floatModel}`);
}

export function buildHarness(decompDir, floatModel) {
    const output = harnessPath(floatModel);
    const source = path.join(decompDir, "zatacka.cpp");
    if (!fs.existsSync(source)) fail(`Can't find ${source}. Run 'git submodule update --init', or use --decomp to specify where zatacka-decomp is.`);
    fs.mkdirSync(BUILD_DIR, { recursive: true });

    // Minimal source transformations needed to compile the original source code with a modern compiler.
    // We count the replacements so that we notice if the source code changes in a way that we need to handle.
    let generated = fs.readFileSync(source, "utf-8");
    generated = replaceExactly(generated, /^\s*asm\s.*$/gm, "// (inline asm removed)", 5);
    generated = replaceExactly(generated, /^void main\(void\)$/gm, "void zatacka_main(void)", 1);
    if (floatModel === "double") { // takes README.md#float32-precision out of the equation
        generated = replaceExactly(generated, /^float (x|y|dir)\[/gm, "double $1[", 3);
    }
    const generatedDir = path.join(BUILD_DIR, `generated-${floatModel}`);
    fs.mkdirSync(generatedDir, { recursive: true });
    fs.writeFileSync(path.join(generatedDir, "zatacka.generated.cpp"), generated);

    const harnessDir = path.join(HERE, "original-harness");
    execFileSync(
        "g++",
        [
            "-std=gnu++14",
            "-O2",
            // Evaluate float/double arithmetic with x87 extended precision, like the original:
            ...(floatModel === "float" ? ["-mfpmath=387", "-fexcess-precision=standard"] : []),
            "-Wall",
            "-Wno-register",
            "-Wno-format-truncation",
            "-I",
            path.join(harnessDir, "shim"),
            "-I",
            generatedDir,
            path.join(harnessDir, "harness.cpp"),
            "-o",
            output,
        ],
        { stdio: "inherit" },
    );
}

function replaceExactly(text, regex, replacement, expectedCount) {
    const actualCount = [...text.matchAll(regex)].length;
    if (actualCount !== expectedCount) {
        fail(`Expected ${expectedCount} matches of ${regex} in zatacka.cpp but found ${actualCount}. Please update the source transformations in ${path.basename(import.meta.url)}.`);
    }
    return text.replace(regex, replacement);
}

export function runOriginal(harness, { players, rounds, seed, botSeed, holes, maxTicks, steering = "bots", dumps = [] }) {
    requireBuilt(harness);
    const result = spawnSync(
        harness,
        [
            ...["--players", players.join(","), "--rounds", rounds, "--seed", seed, "--bot-seed", botSeed, "--holes", holes ? "on" : "off", "--max-ticks", maxTicks, "--steering", steering],
            ...dumps.flatMap(({ round, tick }) => ["--dump", `${round}:${tick}`]),
        ],
        { encoding: "utf-8", maxBuffer: 1 << 30 },
    );
    if (result.status !== 0) fail(`Harness exited with ${result.status}:\n${result.stderr}`);

    const roundsPlayed = [];
    let current = null;
    for (const line of result.stdout.split("\n")) {
        if (line === "") continue;
        const record = JSON.parse(line);
        switch (record.type) {
            case "roundStart":
                current = { round: record.round, start: record, ticks: [], dumps: {} };
                break;
            case "canvasDump":
                (current ?? roundsPlayed[roundsPlayed.length - 1]).dumps[record.tick] = record.pixels;
                break;
            case "tick":
                current.ticks.push(record);
                break;
            case "roundEnd":
                current.ticks.push(record);
                current.end = record;
                roundsPlayed.push(current);
                current = null;
                break;
        }
    }
    return roundsPlayed;
}

export function fail(message) {
    console.error(`❌ ${message}`);
    process.exit(1);
}
