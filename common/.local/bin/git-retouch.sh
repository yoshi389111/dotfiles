#!/bin/sh
# Change file timestamp to author date.

git ls-files | while read -r FILE; do
  TIME=$(git log -1 --date=format-local:"%Y%m%d%H%M.%S" --pretty=format:"%ad" "${FILE}")
  touch -t "${TIME}" "${FILE}"
done
