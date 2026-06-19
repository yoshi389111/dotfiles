#!/usr/bin/env bash
# SPDX-License-Identifier: 0BSD

# A simple hexdump script that shows the offset, hex bytes, and ASCII representation.

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <file>" >&2
  exit 1
fi

echo "_ADDR_ +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F  _0123456789ABCDEF_"
od -Ax -tx1z "$1"

