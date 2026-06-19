#!/usr/bin/env bash
# SPDX-License-Identifier: 0BSD

# Delete a merged branches.

git branch --merged | grep -v '\*' | xargs --no-run-if-empty git branch -d
git fetch -p
