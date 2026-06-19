#!/usr/bin/env python3
# SPDX-License-Identifier: 0BSD

# md5lines.py - Compute MD5 hashes for lines in a file
# Usage: md5lines.py [file1 file2 ...]

# Others have implemented similar functionality in various ways, such as:
#
# ```shell
# while IFS= read -r LINE ; do printf "%s\n" "$(printf "%s" "$LINE" | md5sum) $LINE" ; done < INPUTFILE
# ```
#
# ```perl
# perl -MDigest::MD5=md5_hex -ne 'chomp; print md5_hex($_)," $_\n"' < INPUTFILE
# ```

import sys
import hashlib
from typing import TextIO


def md5_line(line: str) -> str:
    return hashlib.md5(line.encode("utf-8")).hexdigest()


def process_file(f: TextIO) -> None:
    for line in f:
        line = line.rstrip("\n")
        h = md5_line(line)
        print(f"{h}  {line}")


def main() -> None:
    if len(sys.argv) > 1:
        for filename in sys.argv[1:]:
            with open(filename, encoding="utf-8") as f:
                process_file(f)
    else:
        process_file(sys.stdin)


if __name__ == "__main__":
    main()
