#!/usr/bin/env bash
# usage: update.sh

set -eu

SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=${SCRIPT_PATH%/*}
PROJECT_DIR=${SCRIPT_DIR%/*}
RCFILE=~/.bashrc

if [[ -f "$RCFILE" ]]; then
  sed -i '/^\. ~\/\.bashrc\.public$/d' "$RCFILE"
  echo '. ~/.bashrc.public' >> "$RCFILE"
else
  cp "$PROJECT_DIR/init.bashrc" "$RCFILE"
fi

"$SCRIPT_DIR/dispatch_env.sh" "$SCRIPT_DIR/update_env.sh"
