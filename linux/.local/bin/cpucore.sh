#!/bin/sh

P_CPU=$( grep -F 'physical id' /proc/cpuinfo | sort -u | wc -l )
CORES=$( grep -F 'cpu cores' /proc/cpuinfo | sort -u | sed 's/.*: //' )
L_PRC=$( grep -Fc 'processor' /proc/cpuinfo )

if [ "$P_CPU" -eq 0 ] || [ "$CORES" -eq 0 ]; then
  echo "Error: /proc/cpuinfo から情報を取得できませんでした。" >&2
  exit 1
fi

H_TRD=$(( L_PRC /  P_CPU / CORES ))

## usage: print_num_with_units NUM UNIT UNITS
print_num_with_units() {
  if [ "$1" -eq 1 ]; then
    printf "%s %s" "$1" "$2"
  else
    printf "%s %s" "$1" "$3"
  fi
}

print_num_with_units "$L_PRC" "processor" "processors"
printf " = "
print_num_with_units "$P_CPU" "socket" "sockets"
printf " x "
print_num_with_units "$CORES" "core" "cores"
printf " x "
print_num_with_units "$H_TRD" "thread" "threads"
printf "\n"
