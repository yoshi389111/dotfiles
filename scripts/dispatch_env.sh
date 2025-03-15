#!/bin/bash
# usage: dispatch_env.sh SCRIPT_PATH

SCRIPT_PATH="$1"
BASE_DIR="$(cd $(dirname $0)/.. && pwd)"
SYS_NAME="$(uname -s)"
REL_NAME="$(uname -r)"

"$SCRIPT_PATH" "$BASE_DIR/common"

if [[ "$SYS_NAME" = 'Darwin' && -d "$BASE_DIR/mac" ]]; then
  # MacOS
  "$SCRIPT_PATH" "$BASE_DIR/mac"

elif [[ "$SYS_NAME" = 'Linux' ]]; then
  # Linux

  if [[ -d "$BASE_DIR/linux" ]]; then
    # General Linux
    "$SCRIPT_PATH" "$BASE_DIR/linux"
  fi

  if [[ "$REL_NAME" == *microsoft-standard-WSL2 && -d "$BASE_DIR/wsl2" ]]; then
    # WSL2
    "$SCRIPT_PATH" "$BASE_DIR/wsl2"

  elif [[ "$REL_NAME" == *Microsoft && -d "$BASE_DIR/wsl1" ]]; then
    # WSL1
    "$SCRIPT_PATH" "$BASE_DIR/wsl1"

  else
    : # other Linux
  fi

  # npm completion
  if command -v npm >/dev/null; then
    mkdir -p ~/.local/share/bash-completion/completions
    npm completion > ~/.local/share/bash-completion/completions/npm
  fi


elif [[ "$SYS_NAME" == MINGW* && -d "$BASE_DIR/mingw" ]]; then
  # MinGW (e.g. git for windows)
  "$SCRIPT_PATH" "$BASE_DIR/mingw"

else
  : # other unix
fi
