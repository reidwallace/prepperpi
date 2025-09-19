#!/usr/bin/env bash
set -euo pipefail
LIB_DIR="/mnt/library/10_Wikipedia_ZIM"
LIB_XML="$LIB_DIR/library.xml"
mkdir -p "$LIB_DIR"
rm -f "$LIB_XML"; touch "$LIB_XML"
if ! command -v kiwix-manage >/dev/null 2>&1; then
  echo "kiwix-manage not found. Install kiwix-tools."
  exit 0
fi
shopt -s nullglob
for zim in "$LIB_DIR"/*.zim; do
  echo "Adding $zim"
  kiwix-manage "$LIB_XML" add "$zim"
done
echo "Library written: $LIB_XML"
