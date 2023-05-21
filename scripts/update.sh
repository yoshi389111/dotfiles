#!/bin/bash
# usage: update.sh 

SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR"/..; pwd)"
RCFILE=~/.bashrc

if [[ -f "$RCFILE" ]]; then
    sed -i '/^\. ~\/\.bashrc\.public$/d' "$RCFILE"
    echo '. ~/.bashrc.public' >> "$RCFILE"
else
    cp "$PROJECT_DIR/init.bashrc" "$RCFILE"
fi

"$SCRIPT_DIR/dispatch_env.sh" "$SCRIPT_DIR/update_env.sh"
