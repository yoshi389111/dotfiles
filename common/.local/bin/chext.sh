#!/bin/sh
# Rename file extensions for given source files
# Usage: chext.sh <old-ext> <new-ext> <source-files...>
# Example:
# ```
# chext.sh .c .cpp file1.c file2.c
# ```

set -eu

if [ $# -lt 3 ] ; then
    echo "Usage: ${0##*/} <old-ext> <new-ext> <source-files...>" >&2
    exit 1
fi

old_ext=$1
new_ext=$2
shift 2

for file in "$@" ; do
    if [ ! -f "$file" ] ; then
        echo "File not found: $file" >&2
        continue
    fi

    new_file="${file%"${old_ext}"}$new_ext"

    mv "$file" "$new_file"
done
