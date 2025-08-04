#!/bin/bash

if [[ $# -ne 1 || "$1" = "-h" || "$1" = "--help" ]]; then
  echo "Usage: ${0##*/} { ERROR_NUMBER | ERROR_NAME }" >&2
  exit 1

elif [[ ! ( "$1" =~ ^E[A-Z0-9]+$ || "$1" =~ ^[1-9][0-9]*$ ) ]]
then
  echo "illegal argument." >&2
  exit 1

elif ! find /usr/include -name 'errno*.h' -print0 |
  xargs -0 -r grep -Eh \
    -e "^\\s*#\\s*define\\s+E[A-Z0-9]+\\s+$1\\>" \
    -e "^\\s*#\\s*define\\s+$1\\s+[1-9][0-9]*\\>" \
    -e "^\\s*#\\s*define\\s+$1\\s+E[A-Z0-9]+\\>"
then
  echo "errno not found($1)." >&2
  exit 1
fi
