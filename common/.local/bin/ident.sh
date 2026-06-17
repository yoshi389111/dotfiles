#!/usr/bin/env bash
# This is a simplified implementation of the RCS `ident` command.
# e.g. "$Id: foo.c,v 1.1 2023/01/01 12:34:56 user Exp $"

set -euo pipefail

if [ $# -ne 1 ] ; then
  echo "Usage: $0 <FILE>" >&2
  exit 1
fi

grep -aoE '\$\w*:[ -#%-~]*\$' "$1" || :
