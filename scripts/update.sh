#!/usr/bin/env bash
set -euo pipefail
APP_ROOT="/opt/prepperpi"
LIB_ROOT="/mnt/library"
MANIFEST="$APP_ROOT/manifests/update_manifest.json"
LOG="/var/log/prepperpi/update.log"
mkdir -p "$(dirname "$LOG")"

log(){ echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

log "=== Content Update Start ==="

if [[ ! -f "$MANIFEST" ]]; then
  log "Manifest missing: $MANIFEST"; exit 1
fi

items=$(jq -c '.items[]' "$MANIFEST")
for item in $items; do
  url=$(echo "$item" | jq -r '.url')
  dest_rel=$(echo "$item" | jq -r '.dest_rel')
  filename=$(echo "$item" | jq -r '.filename')
  checksum_url=$(echo "$item" | jq -r '.checksum_url // empty')
  checksum=$(echo "$item" | jq -r '.checksum // empty')

  dest_dir="$LIB_ROOT/$dest_rel"
  mkdir -p "$dest_dir"
  tmp="/tmp/${filename}.part"

  log "Download: $url"
  aria2c -x 8 -s 8 -o "$(basename "$tmp")" -d /tmp "$url"

  if [[ -n "$checksum_url" ]]; then
    curl -fsSL "$checksum_url" -o "/tmp/${filename}.sha256" || true
    if [[ -s "/tmp/${filename}.sha256" ]]; then
      (cd /tmp && sha256sum -c "/tmp/${filename}.sha256" --ignore-missing || true)
    fi
  elif [[ -n "$checksum" ]]; then
    echo "${checksum}  $(basename "$tmp")" > "/tmp/${filename}.sha256"
    (cd /tmp && sha256sum -c "/tmp/${filename}.sha256")
  else
    log "No checksum for $filename"
  fi

  if [[ -f "$dest_dir/$filename" ]]; then
    mkdir -p "$LIB_ROOT/99_Archive"
    ts=$(date +%Y%m%d-%H%M%S)
    mv "$dest_dir/$filename" "$LIB_ROOT/99_Archive/${filename}.${ts}.old"
  fi

  mv "$tmp" "$dest_dir/$filename"
  log "Saved: $dest_dir/$filename"
done

if command -v kiwix-manage >/dev/null 2>&1; then
  /opt/prepperpi/scripts/rebuild_kiwix_library.sh || true
  systemctl restart kiwix-serve.service || true
fi

log "=== Content Update Done ==="
