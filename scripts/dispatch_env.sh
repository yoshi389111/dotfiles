#!/usr/bin/env bash
# usage: dispatch_env.sh SCRIPT_PATH

set -eu

SCRIPT_PATH=$(realpath "$1")
SCRIPT_DIR=${SCRIPT_PATH%/*}
PROJECT_DIR=${SCRIPT_DIR%/*}
SYS_NAME=$(uname -s)
REL_NAME=$(uname -r)

"$SCRIPT_PATH" "$PROJECT_DIR/common"

if [[ "$SYS_NAME" = 'Darwin' && -d "$PROJECT_DIR/mac" ]]; then
  # MacOS
  "$SCRIPT_PATH" "$PROJECT_DIR/mac"

elif [[ "$SYS_NAME" = 'Linux' ]]; then
  # Linux

  if [[ -d "$PROJECT_DIR/linux" ]]; then
    # General Linux
    "$SCRIPT_PATH" "$PROJECT_DIR/linux"
  fi

  if [[ "$REL_NAME" == *microsoft-standard-WSL2 && -d "$PROJECT_DIR/wsl2" ]]; then
    # WSL2
    "$SCRIPT_PATH" "$PROJECT_DIR/wsl2"

  elif [[ "$REL_NAME" == *Microsoft && -d "$PROJECT_DIR/wsl1" ]]; then
    # WSL1
    "$SCRIPT_PATH" "$PROJECT_DIR/wsl1"

  else
    : # other Linux
  fi

  # npm completion
  if command -v npm >/dev/null; then
    mkdir -p ~/.local/share/bash-completion/completions
    npm completion > ~/.local/share/bash-completion/completions/npm
  fi


elif [[ "$SYS_NAME" == MINGW* && -d "$PROJECT_DIR/mingw" ]]; then
  # MinGW (e.g. git for windows)
  "$SCRIPT_PATH" "$PROJECT_DIR/mingw"

else
  : # other unix
fi
