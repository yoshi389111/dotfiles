#!/bin/bash
# usage: update.sh 

SCRIPT_DIR="$(cd $(dirname $0); pwd)"

"$SCRIPT_DIR/dispatch_env.sh" "$SCRIPT_DIR/update_env.sh"
