#!/bin/sh
# convert latex to svg

tex="$1"

curl -LsS https://latex.codecogs.com/svg.latex --url-query "$tex"
echo
