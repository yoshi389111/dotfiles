#!/bin/sh
# SPDX-License-Identifier: 0BSD

# Get this repository name.

basename -s .git "$(git remote get-url origin)"
