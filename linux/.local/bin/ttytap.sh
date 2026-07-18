#!/usr/bin/env bash
set -euo pipefail
error() { printf "%s\n" "$*" >&2; exit 1 ;}
[ $# -ne 1 ] && error "Usage: $0 <TTY_NAME>"
[ "$(id -u)" -ne 0 ] && error "Error: must be run as root"

tty_name="$1" tty_pid=""
while read -r ppid pid sid; do
  [ "$pid" -eq "$sid" ] && tty_pid="$ppid"
done < <(ps -o "ppid= pid= sid=" -t "$tty_name")
[ -z "$tty_pid" ] && error "Error: tty not found '$tty_name'"

ptmx_fds=""
while IFS= read -r line; do
  line="${line##*/}"  # as basename
  [ -z "$ptmx_fds" ] && ptmx_fds="$line" || ptmx_fds="$ptmx_fds,$line"
done < <(find "/proc/$tty_pid/fd" -type l -lname /dev/ptmx)
[ -z "$ptmx_fds" ] && error "Error: ptmx_fds not found '$tty_name'($tty_pid)"

strace -q -s 0 -e read -e "read=$ptmx_fds" -p "$tty_pid" 2>&1 |
  stdbuf -oL sed -Ee '/^ \| /!d;s/^.{10}(.*).{20}$/\1/' |
  stdbuf -o0 xxd -r -p
