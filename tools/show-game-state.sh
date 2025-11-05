#!/bin/bash

set -euo pipefail

USAGE="For example: $0 7fffd8010ff6"

base_address="${1:?Please specify base address. $USAGE}"

sudo scanmem `pgrep dosbox` --errexit --command "option dump_with_ascii 0;dump ${base_address} 72;exit" 2>/dev/null | $(dirname $0)/interpret-scanmem-output.py
