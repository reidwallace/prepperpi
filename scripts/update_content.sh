#!/bin/bash
# PrepperPi Content Update Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/opt/prepperpi/logs/content_update.log"
CONFIG_FILE="$BASE_DIR/config/kiwix.conf"
LOCK_FILE="/tmp/prepperpi_update.lock"

# Load configuration
source "$CONFIG_FILE"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if update is already running
if [[ -f "$LOCK_FILE" ]]; then
    log "Content update already in progress. Exiting."
    exit 1
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

log "Starting content update..."

# Create data directory if it doesn't exist
mkdir -p "$KIWIX_DATA_DIR"
cd "$KIWIX_DATA_DIR"

# Download content sources
for source in "${CONTENT_SOURCES[@]}"; do
    filename=$(basename "$source")
    log "Downloading $filename..."
    
    if wget -c -t 3 -T 30 "$source" -O "$filename.tmp"; then
        mv "$filename.tmp" "$filename"
        log "Successfully downloaded $filename"
    else
        log "Failed to download $filename"
        rm -f "$filename.tmp"
    fi
done

# Update Kiwix library
log "Updating Kiwix library..."
kiwix-manage "$KIWIX_LIBRARY_FILE" add *.zim || log "Warning: Some files may not have been added to library"

log "Content update completed"
