#!/bin/bash
# usage: update_env.sh TARGET_DIR

TARGET_DIR="$1"

create_link() {
  mkdir -p ~/"$(dirname $1)"
  rm -f ~/"$1"
  echo ln -s "$TARGET_DIR/$1" ~/"$1"
  ln -s "$TARGET_DIR/$1" ~/"$1"
}

for FILE in $(cd "$TARGET_DIR"; find ./ -type f -name '.*'); do
  create_link "${FILE#./}"
done

if [ -d "$TARGET_DIR"/.git_template ]; then
  for FILE in $(cd "$TARGET_DIR"; find .git_template -type f); do
    create_link "$FILE"
  done
fi

if [ -d "$TARGET_DIR"/.local ]; then
  for FILE in $(cd "$TARGET_DIR"; find .local -type f); do
    create_link "$FILE"
  done
fi
