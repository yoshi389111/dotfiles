#!/bin/sh
set -eu

os=""
detail=""
kernel="$(uname -sr)"
machine="$(uname -m)"

case "$(uname -s)" in
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      os="WSL"
    else
      os="Linux"
    fi

    PRETTY_NAME=""
    NAME=""
    if [ -r /etc/os-release ]; then
      # shellcheck source=/dev/null
      . /etc/os-release
    elif [ -r /usr/lib/os-release ]; then
      # shellcheck source=/dev/null
      . /usr/lib/os-release
    fi
    detail="${PRETTY_NAME:-${NAME:-Linux}}"
    [ "$os" = "Linux" ] && os="${NAME:-Linux}"
    ;;

  Darwin)
    os="macOS"
    if command -v sw_vers >/dev/null 2>&1; then
      productName="$(sw_vers -productName)"
      productVersion="$(sw_vers -productVersion)"
      detail="$productName $productVersion"
    else
      detail="macOS"
    fi
    ;;

  MINGW*|MSYS*)
    if command -v pacman >/dev/null 2>&1; then
      os="MSYS2"
      msysVersion="$(pacman -Q msys2-runtime 2>/dev/null)"
      msysVersion="${msysVersion#msys2-runtime }"
      msysVersion="${msysVersion%%-*}"
      detail="$os (${msysVersion})"
    else
      os="Git Bash"
      gitVersion="$(git --version 2>/dev/null)"
      gitVersion="${gitVersion#git version }"
      detail="$os ($gitVersion)"
    fi
    ;;

  CYGWIN*)
    os="Cygwin"
    detail="Cygwin"
    ;;

  *)
    os="$(uname -s)"
    detail="$os"
    ;;
esac

printf 'OS      : %s\n' "$os"
printf 'Detail  : %s\n' "$detail"
printf 'Kernel  : %s\n' "$kernel"
printf 'Arch    : %s\n' "$machine"
