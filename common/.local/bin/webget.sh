#!/bin/sh
# download a file from a URL
# usage: webget.sh <URL> <OUTPUT_FILE>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <URL> <OUTPUT_FILE>"
    exit 1
fi

URL="$1"
OUTPUT_FILE="$2"

if command -v curl >/dev/null 2>&1; then
    curl -LsS "$URL" -o "$OUTPUT_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$URL" -O "$OUTPUT_FILE"
elif command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    python3 -c "import sys, urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])" "$URL" "$OUTPUT_FILE"
elif command -v busybox >/dev/null 2>&1 && busybox wget --help >/dev/null 2>&1; then
    busybox wget -q "$URL" -O "$OUTPUT_FILE"
elif command -v fetch >/dev/null 2>&1; then
    fetch -o "$OUTPUT_FILE" "$URL"
else
    echo "Error: No suitable download tool found."
    exit 1
fi
