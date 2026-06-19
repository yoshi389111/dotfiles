#!/usr/bin/env bash
# SPDX-License-Identifier: 0BSD

# This is a simplified implementation of the SCCS `what` command.
# e.g. "@(#) foo.c 1.1 2023/01/01"

set -euo pipefail

if [ $# -ne 1 ] ; then
  echo "Usage: $0 <FILE>" >&2
  exit 1
fi

grep -aoE '@\(#\)[ -~]*' "$1" || :
