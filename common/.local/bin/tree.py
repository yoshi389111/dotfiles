#!/usr/bin/env python3

# Show directory tree
# (C) 2023 SATO Yoshiyuki
# This software is released under the MIT License.
# https://opensource.org/licenses/mit-license.php

import argparse
import datetime
import fnmatch
import grp
import os
import pwd
import signal
import sys
from typing import List

NAME = "tree.py"
VERSION = "0.2.0"
DESCRIPTION = "show directory tree."

loc = (os.environ.get("LC_ALL") or os.environ.get("LANG") or "C").lower()
lang = loc.split('.')[0].split('_')[0]

if lang in ('ja', 'zh', 'ko'):
    branch_file = [ " ├ ", " └ " ]
    branch_next = [ " │ ", "    " ]
elif 'utf-8' in loc or 'utf8' in loc:
    branch_file = [ " ├─ ", " └─ " ]
    branch_next = [ " │  ", "    " ]
else:
    branch_file = [ " +- ", " `- " ]
    branch_next = [ " |  ", "    " ]


def arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=DESCRIPTION)

    parser.add_argument(
        "DIRECTORIES", nargs='*', help="target directories"
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
        action='store_true',
        help='all file (within "dot file")',
    )

    parser.add_argument(
        "-d",
        "--directory-only",
        action='store_true',
        help='directory only',
    )

    parser.add_argument(
        "-p",
        "--show-permission",
        action='store_true',
        help="`ls -l' like format",
    )

    parser.add_argument(
        "-l",
        "--symbolic-link",
        action='store_true',
        help="show symbolic link path",
    )

    parser.add_argument(
        "-I",
        "--ignore-pattern",
        action='append',
        help="specify paths to ignore with wildcards",
        default=[],
    )

    return parser

class ShowTree:

    def __init__(self):
        self.args = arg_parser().parse_args()

    def get_dir(self, path: str) -> List[str]:
        try:
            files = os.listdir(path)
            if self.args.directory_only:
                files = [f for f in files if os.path.isdir(os.path.join(path, f))]
            if not self.args.all_files:
                files = [f for f in files if not f.startswith(".")]
            files = [f for f in files if not any(fnmatch.fnmatch(f, pattern) for pattern in self.args.ignore_pattern)]
            return files
        except PermissionError:
            return []

    def str_perm(self, mode: int) -> str:
        perm = ""
        work = mode & 0o170000
        if work == 0o140000:
            perm = "s" # socket
        elif work == 0o120000:
            perm = "l" # symlink
        elif work == 0o110000:
            perm = "n" # named pipe
        elif work == 0o100000:
            perm = "-" # normal file
        elif work == 0o060000:
            perm = "b" # block device
        elif work == 0o040000:
            perm = "d" # directory
        elif work == 0o020000:
            perm = "c" # character device
        elif work == 0o010000:
            perm = "p" # 
        else:
            perm = " " # failback

        perm += "r" if mode & 0o000400 else "-"
        perm += "w" if mode & 0o000200 else "-"

        work = mode & 0o004100
        if work == 0o004100:
            perm += "s"
        elif work == 0o004000:
            perm += "S"
        elif work == 0o000100:
            perm += "x"
        else:
            perm += "-"

        perm += "r" if mode & 0o000040 else "-"
        perm += "w" if mode & 0o000020 else "-"

        work = mode & 0o002010
        if work == 0o002010:
            perm += "s"
        elif work == 0o002000:
            perm += "S"
        elif work == 0o000010:
            perm += "x"
        else:
            perm += "-"

        perm += "r" if mode & 0o000004 else "-"
        perm += "w" if mode & 0o000002 else "-"

        work = mode & 0o001001
        if work == 0o001001:
            perm += "t"
        elif work == 0o001000:
            perm += "T"
        elif work == 0o000001:
            perm += "x"
        else:
            perm += "-"

        return perm

    def get_user_name(self, uid: int) -> str:
        try:
            info = pwd.getpwuid(uid)
            return info.pw_name
        except ImportError:
            return str(uid)

    def get_group_name(self, gid: int) -> str:
        try:
            info = grp.getgrgid(gid)
            return info.gr_name
        except ImportError:
            return str(gid)

    def print_ls_format(self, filename: str) -> None:
        stat = os.stat(filename)
        perm = self.str_perm(stat.st_mode)
        print(perm + " ", end="")

        print(
            "{:10s} {:10s}".format(
                self.get_user_name(stat.st_uid),
                self.get_group_name(stat.st_gid)),
            end="")

        if (stat.st_mode&0o060000)==0o060000 or (stat.st_mode&0o020000)==0o020000:
            print("0x{:08x} ".format(stat.st_dev), end="")
        else:
            print(" {:9d} ".format(stat.st_size), end="")
        update_time = datetime.datetime.fromtimestamp(stat.st_mtime)
        print(update_time.strftime('%Y-%m-%d %H:%M:%S '), end="")

    def print_file(self, dir: str, filename: str, branch_pat: str) -> None:
        fullpath = (dir + "/" + filename) if len(dir) != 0 else filename
        if self.args.show_permission:
            self.print_ls_format(fullpath)
        print(branch_pat, end="")
        if os.path.isdir(fullpath) and not filename.endswith("/"):
            filename += "/"
        print(filename, end="")
        if self.args.symbolic_link and os.path.islink(fullpath):
            print(" -> " + os.readlink(fullpath), end="")
        print()

    def print_tree_sub(self, path: str, branch_pat: str) -> None:
        files = self.get_dir(path)
        for i, file in enumerate(files):
            index = 1 if i == len(files) - 1 else 0
            if os.path.isdir(os.path.join(path, file)):
                self.print_file(path, file, branch_pat + branch_file[index])
                self.print_tree_sub(path + "/" + file, branch_pat + branch_next[index])
            else:
                self.print_file(path, file, branch_pat + branch_file[index])

    def print_tree(self, path: str) -> None:
        self.print_file("", path, "")
        self.print_tree_sub(path, "")

    def execute(self) -> None:
        directories = []
        if len(self.args.DIRECTORIES) == 0:
            directories = [ "." ]
        else:
            directories = self.args.DIRECTORIES
        for path in directories:
            self.print_tree(path)

if __name__ == "__main__":
    try:
        ShowTree().execute()
    except KeyboardInterrupt:
        # Suppress stacktraces, but exit with SIGINT
        sys.exit(128 + signal.SIGINT)
