#!/usr/bin/env bash
# This script typically needs to be run as root.

set -euo pipefail

PROCESS_ID=`pgrep dosbox`

readonly RED=0
readonly YELLOW=1
readonly ORANGE=2
readonly GREEN=3
readonly PINK=4
readonly BLUE=5

readonly BASE_ADDRESS=0x7fffd8010ff6

readonly X_COORDS_ADDRESS=$(( BASE_ADDRESS ))
readonly Y_COORDS_ADDRESS=$(( BASE_ADDRESS + 24 ))
readonly DIRECTIONS_ADDRESS=$(( BASE_ADDRESS + 48 ))

function toHex() {
  raw_hex="$(printf %x "$1")"
  echo "0x$raw_hex"
}


scanmem_command="option endianness 1;write float32 $(toHex $BASE_ADDRESS) 450;exit"

scanmem ${PROCESS_ID:?} --errexit --command "${scanmem_command:?}"
