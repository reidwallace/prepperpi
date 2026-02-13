#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
source "$BASE_DIR/config/kiwix.conf"

mkdir -p "$KIWIX_DATA_DIR"
rm -f "$KIWIX_LIBRARY_FILE"

if ! command -v kiwix-manage >/dev/null 2>&1; then
  echo "kiwix-manage not found. Install kiwix-tools."
  exit 0
fi

shopt -s nullglob
for zim in "$KIWIX_DATA_DIR"/*.zim; do
  echo "Adding $zim"
  kiwix-manage "$KIWIX_LIBRARY_FILE" add "$zim"
done
echo "Library written: $KIWIX_LIBRARY_FILE"
