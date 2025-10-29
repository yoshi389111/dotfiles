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
    .local/bin/*.sh) DST_FILE="${FILE%.sh}" ;;
    .local/bin/*.py) DST_FILE="${FILE%.py}" ;;
	  .local/bin/*.pl) DST_FILE="${FILE%.pl}" ;;
    *) DST_FILE="$FILE" ;;
    esac
    echo "ln -sf $SRC_DIR/$FILE $DST_DIR/$DST_FILE"
    ln -sf "$SRC_DIR/$FILE" "$DST_DIR/$DST_FILE"
  done
