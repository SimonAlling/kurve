#!/bin/bash

set -euo pipefail

sudo scanmem `pgrep dosbox` --errexit --command "option dump_with_ascii 0;dump 0x7fffd8010ff6 72;exit" 2>/dev/null | $(dirname $0)/parse-scanmem-output.py
