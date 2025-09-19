#!/usr/bin/env bash
# Idempotent installer skeleton for PrepperPi
set -euo pipefail

echo "[+] PrepperPi install starting..."

# Create needed directories
mkdir -p /opt/prepperpi/{data,logs,backup}
mkdir -p /opt/prepperpi/data/zim

# Optional: copy example configs if real ones don't exist
for f in network.conf kiwix.conf system.conf; do
  if [ ! -f "config/$f" ] && [ -f "config/${f}.example" ]; then
    cp "config/${f}.example" "config/$f"
    echo "[i] Created config/$f from example; please edit values."
  fi
done

# Enable and start services if present
if systemctl list-unit-files | grep -q kiwix-serve; then
  sudo systemctl enable kiwix-serve || true
  sudo systemctl restart kiwix-serve || true
fi

echo "[+] PrepperPi install complete."
