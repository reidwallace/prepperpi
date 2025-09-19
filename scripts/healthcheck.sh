#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-/opt/prepperpi/logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/healthcheck.log"

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

echo "$(timestamp) :: Healthcheck start" >> "$LOG_FILE"

# Check disk space
df -h / | awk 'NR==2{print strftime("%Y-%m-%d %H:%M:%S"),":: Disk:",$5}' >> "$LOG_FILE"

# Check Kiwix port
KIWIX_PORT="${KIWIX_PORT:-8080}"
if nc -z localhost "$KIWIX_PORT"; then
  echo "$(timestamp) :: Kiwix port $KIWIX_PORT OK" >> "$LOG_FILE"
else
  echo "$(timestamp) :: Kiwix port $KIWIX_PORT DOWN" >> "$LOG_FILE"
fi

# Check HTTP (nginx) port 80
if nc -z localhost 80; then
  echo "$(timestamp) :: HTTP port 80 OK" >> "$LOG_FILE"
else
  echo "$(timestamp) :: HTTP port 80 DOWN" >> "$LOG_FILE"
fi

echo "$(timestamp) :: Healthcheck end" >> "$LOG_FILE"
