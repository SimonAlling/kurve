#!/usr/bin/env node

const { spawnSync } = require("child_process");
const fs = require("fs");

main(...process.argv.slice(2));

function main(executable, stringToReplace) {
  spawnSync("git", [ "restore", executable ]);
  const originalFileContent = fs.readFileSync(executable);
  for (let i = 32; i < 127; i += stringToReplace.length) {
    const codePoints = [...Array(stringToReplace.length).keys()].map(x => spaceIfUnsafe(i + x));
    const replacement = String.fromCodePoint(...codePoints);
    console.log("Current string:", replacement);
    fs.writeFileSync(executable, replace(originalFileContent, stringToReplace, replacement));
    spawnSync("dosbox", [ executable ]);
    // Screenshot can be taken now.
  }
  spawnSync("git", [ "restore", executable ]);
}

function spaceIfUnsafe(codePoint) {
  return codePoint >= 32 && codePoint < 127 ? codePoint : 32;
}

// https://github.com/juliangruber/buffer-replace/blob/a5e43eb7c457d048f47712e607b13a16bf5f5bd4/index.js
function replace(buf, original, replacement) {
  const idx = buf.indexOf(original);
  if (idx === -1) return buf;
  const b = Buffer.from(replacement);
  const before = buf.slice(0, idx);
  const after = replace(buf.slice(idx + original.length), original, b);
  const len = idx + b.length + after.length;
  return Buffer.concat([ before, b, after ], len);
}
