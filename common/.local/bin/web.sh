#!/bin/sh
# easy web server

port=8000

if type python3 >/dev/null 2>&1; then
  python3 -m http.server $port
elif type ruby >/dev/null 2>&1; then
  ruby -run -e httpd . -p $port
elif type busybox >/dev/null 2>&1; then
  busybox httpd -f -p $port
else
  echo "No web server found"
fi
