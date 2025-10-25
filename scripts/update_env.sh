#!/usr/bin/env bash
# usage: update_env.sh SRC_DIR

set -eu

SRC_DIR=$1
DST_DIR=~

find "$SRC_DIR/" -type f |
  while IFS= read -r FILE; do
    FILE=${FILE#"${SRC_DIR}/"}
    mkdir -p "$DST_DIR/${FILE%/*}" 2>/dev/null || true
    case "$FILE" in
    *.sh) DST_FILE="${FILE%.sh}" ;;
    *.py) DST_FILE="${FILE%.py}" ;;
	*.pl) DST_FILE="${FILE%.pl}" ;;
    *) DST_FILE="$FILE" ;;
    esac
    echo "ln -sf $SRC_DIR/$FILE $DST_DIR/$DST_FILE"
    ln -sf "$SRC_DIR/$FILE" "$DST_DIR/$DST_FILE"
  done
