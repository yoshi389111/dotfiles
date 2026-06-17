#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ] ; then
  echo "Usage: $0 <FILE>" >&2
  exit 1
fi

grep -a -o '[[:print:]]\{4,\}' "$1" | sort -u
