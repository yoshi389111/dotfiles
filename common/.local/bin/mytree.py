#!/usr/bin/env python3

# Show directory tree
# (C) 2023 SATO Yoshiyuki
# This software is released under the MIT License.
# https://opensource.org/licenses/mit-license.php

import argparse
import datetime
import fnmatch
import os
import signal
import stat
import sys
from typing import List

NAME = "tree.py"
VERSION = "0.3.0"
DESCRIPTION = "show directory tree."


def arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=DESCRIPTION)

    parser.add_argument(
        "DIRECTORIES", nargs="*", default=["."], help="target directories"
    )

    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version="{} {}".format(NAME, VERSION),
    )

    parser.add_argument(
        "-a",
        "--all-files",
        action="store_true",
        help='all file (within "dot file")',
    )

    parser.add_argument(
        "-d",
        "--directory-only",
        action="store_true",
        help="directory only",
    )

    parser.add_argument(
        "-p",
        "--show-permission",
        action="store_true",
        help="`ls -l' like format",
    )

    parser.add_argument(
        "-l",
        "--symbolic-link",
        action="store_true",
        help="show symbolic link path",
    )

    parser.add_argument(
        "-I",
        "--ignore-pattern",
        action="append",
        help="specify paths to ignore with wildcards",
        default=[],
    )

    parser.add_argument(
        "-E",
        "--east-asian-width",
        choices=["ascii", "always", "never", "auto"],
        default="auto",
        help="Specify how to handle East Asian width: ascii, always, never or auto (default: auto)",
    )

    return parser


class ShowTree:

    def __init__(self):
        self.args = arg_parser().parse_args()

        if self.args.east_asian_width == "auto":
            loc = (os.environ.get("LC_ALL") or os.environ.get("LANG") or "C").lower()
            lang = loc.split(".")[0].split("_")[0]
            if lang in ("ja", "zh", "ko"):
                east_asian_width = "always"
            elif "utf-8" in loc or "utf8" in loc:
                east_asian_width = "never"
            else:
                east_asian_width = "ascii"
        else:
            east_asian_width = self.args.east_asian_width

        if east_asian_width == "always":
            self.prefix_file = [" ├ ", " └ "]
            self.prefix_indent = [" │ ", "    "]
        elif east_asian_width == "never":
            self.prefix_file = [" ├─ ", " └─ "]
            self.prefix_indent = [" │  ", "    "]
        else:
            self.prefix_file = [" +- ", " `- "]
            self.prefix_indent = [" |  ", "    "]

    def is_not_directory_if_need(self, path: str, file: str) -> bool:
        return not self.args.directory_only or os.path.isdir(os.path.join(path, file))

    def is_not_dot_file_if_need(self, file: str) -> bool:
        return self.args.all_files or not file.startswith(".")

    def is_not_ignore_pattern(self, file: str) -> bool:
        return not any(
            fnmatch.fnmatch(file, pattern) for pattern in self.args.ignore_pattern
        )

    def is_displayable(self, path: str, file: str) -> bool:
        return (
            self.is_not_directory_if_need(path, file)
            and self.is_not_dot_file_if_need(file)
            and self.is_not_ignore_pattern(file)
        )

    def get_entries(self, path: str) -> List[str]:
        try:
            return [f for f in os.listdir(path) if self.is_displayable(path, f)]
        except:
            return []

    def get_user_name(self, uid: int) -> str:
        try:
            import pwd

            info = pwd.getpwuid(uid)
            return info.pw_name
        except:
            return str(uid)

    def get_group_name(self, gid: int) -> str:
        try:
            import grp

            info = grp.getgrgid(gid)
            return info.gr_name
        except:
            return str(gid)

    def print_ls_format(self, filename: str) -> None:
        fstat = os.stat(filename)
        perm = stat.filemode(fstat.st_mode)
        user_name = self.get_user_name(fstat.st_uid)
        group_name = self.get_group_name(fstat.st_gid)
        update_time = datetime.datetime.fromtimestamp(fstat.st_mtime)

        print(perm + " ", end="")
        print(
            "{:10s} {:10s}".format(user_name, group_name),
            end="",
        )
        if stat.S_ISBLK(fstat.st_mode) or stat.S_ISCHR(fstat.st_mode):
            print("0x{:08x} ".format(fstat.st_dev), end="")
        else:
            print(" {:9d} ".format(fstat.st_size), end="")
        print(update_time.strftime("%Y-%m-%d %H:%M:%S "), end="")

    def print_file(self, dir: str, filename: str, prefix: str) -> None:
        fullpath = os.path.join(dir, filename)
        if self.args.show_permission:
            self.print_ls_format(fullpath)
        print(prefix, end="")
        if os.path.isdir(fullpath) and not filename.endswith(os.sep):
            filename += os.sep
        print(filename, end="")
        if self.args.symbolic_link and os.path.islink(fullpath):
            print(" -> " + os.readlink(fullpath), end="")
        print()

    def print_tree_sub(self, path: str, prefix: str) -> None:
        files = self.get_entries(path)
        for i, file in enumerate(files):
            prefix_kind = 1 if i == len(files) - 1 else 0
            self.print_file(path, file, prefix + self.prefix_file[prefix_kind])
            fullpath = os.path.join(path, file)
            if os.path.isdir(fullpath):
                self.print_tree_sub(fullpath, prefix + self.prefix_indent[prefix_kind])

    def execute(self) -> None:
        for path in self.args.DIRECTORIES:
            self.print_file("", path, "")
            self.print_tree_sub(path, "")


def main() -> None:
    try:
        ShowTree().execute()
    except KeyboardInterrupt:
        # Suppress stacktraces, but exit with SIGINT
        sys.exit(128 + signal.SIGINT)


if __name__ == "__main__":
    main()
