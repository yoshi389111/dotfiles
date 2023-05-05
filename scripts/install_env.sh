#!/bin/bash
# usage: install_env.sh TARGET_DIR

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
TARGET_DIR="$1"

echo cp "$TARGET_DIR/init.bashrc" ~/.bashrc
cp "$TARGET_DIR/init.bashrc" ~/.bashrc

"$SCRIPT_DIR/update_env.sh" "$TARGET_DIR"
