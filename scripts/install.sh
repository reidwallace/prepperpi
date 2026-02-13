#!/usr/bin/env bash
# Idempotent installer for PrepperPi
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env if present
if [ -f "$BASE_DIR/config/.env" ]; then
    source "$BASE_DIR/config/.env"
fi

ENABLE_KIWIX="${ENABLE_KIWIX:-true}"
ENABLE_UPDATE_TIMER="${ENABLE_UPDATE_TIMER:-true}"
ENABLE_BACKUP_TIMER="${ENABLE_BACKUP_TIMER:-false}"
ENABLE_MONITOR="${ENABLE_MONITOR:-false}"
KIWIX_PORT="${KIWIX_PORT:-8080}"
WEBAPP_PORT="${WEBAPP_PORT:-5001}"

echo "[+] PrepperPi install starting..."

# Install kiwix-tools if not present
if ! command -v kiwix-serve >/dev/null 2>&1; then
    echo "[+] Installing kiwix-tools..."
    apt-get update
    apt-get install -y kiwix-tools
else
    echo "[i] kiwix-tools already installed"
fi

# Create needed directories
mkdir -p /opt/prepperpi/{data,logs,backup}
mkdir -p /opt/prepperpi/data/kiwix

# Copy example configs if real ones don't exist
for f in network.conf kiwix.conf system.conf; do
    if [ ! -f "$BASE_DIR/config/$f" ] && [ -f "$BASE_DIR/config/${f}.example" ]; then
        cp "$BASE_DIR/config/${f}.example" "$BASE_DIR/config/$f"
        echo "[i] Created config/$f from example; please edit values."
    fi
done

# Install systemd services
echo "[+] Installing systemd services..."
for unit in "$BASE_DIR"/systemd/*.service "$BASE_DIR"/systemd/*.timer; do
    [ -f "$unit" ] || continue
    cp "$unit" /etc/systemd/system/
    echo "[i] Installed $(basename "$unit")"
done

# Generate nginx config from template
if [ -f "$BASE_DIR/configs/nginx/prepperpi.conf.template" ]; then
    echo "[+] Generating nginx config..."
    KIWIX_PORT="$KIWIX_PORT" WEBAPP_PORT="$WEBAPP_PORT" envsubst '$KIWIX_PORT $WEBAPP_PORT' \
        < "$BASE_DIR/configs/nginx/prepperpi.conf.template" \
        > "$BASE_DIR/configs/nginx/prepperpi.conf"
    echo "[i] Generated configs/nginx/prepperpi.conf (kiwix:$KIWIX_PORT, webapp:$WEBAPP_PORT)"
fi

systemctl daemon-reload

# Enable/disable services based on .env
if [ "$ENABLE_KIWIX" = "true" ]; then
    systemctl enable prepperpi-kiwix
    echo "[+] Enabled: prepperpi-kiwix"
else
    systemctl disable prepperpi-kiwix 2>/dev/null || true
    echo "[-] Disabled: prepperpi-kiwix"
fi

if [ "$ENABLE_UPDATE_TIMER" = "true" ]; then
    systemctl enable prepperpi-update.timer
    echo "[+] Enabled: prepperpi-update.timer"
else
    systemctl disable prepperpi-update.timer 2>/dev/null || true
    echo "[-] Disabled: prepperpi-update.timer"
fi

if [ "$ENABLE_BACKUP_TIMER" = "true" ]; then
    systemctl enable prepperpi-backup.timer
    echo "[+] Enabled: prepperpi-backup.timer"
else
    systemctl disable prepperpi-backup.timer 2>/dev/null || true
    echo "[-] Disabled: prepperpi-backup.timer"
fi

if [ "$ENABLE_MONITOR" = "true" ]; then
    systemctl enable prepperpi-monitor
    echo "[+] Enabled: prepperpi-monitor"
else
    systemctl disable prepperpi-monitor 2>/dev/null || true
    echo "[-] Disabled: prepperpi-monitor"
fi

echo "[+] PrepperPi install complete."
echo "[i] Run 'sudo bash $BASE_DIR/scripts/update.sh' to download content."
echo "[i] After content is downloaded, start with: sudo systemctl start prepperpi-kiwix"
