#!/bin/bash
# usage: install.sh 

SCRIPT_DIR="$(cd $(dirname $0); pwd)"

"$SCRIPT_DIR/dispatch_env.sh" "$SCRIPT_DIR/install_env.sh"
