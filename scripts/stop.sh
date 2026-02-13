#!/usr/bin/env bash
set -euo pipefail
echo "[+] Stopping PrepperPi services..."
systemctl stop prepperpi-kiwix || true
systemctl stop prepperpi-monitor || true
echo "[+] PrepperPi stopped."
