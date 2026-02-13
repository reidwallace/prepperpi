#!/usr/bin/env bash
set -euo pipefail
echo "[+] Starting PrepperPi services..."
systemctl start prepperpi-kiwix
echo "[+] PrepperPi running at http://$(hostname -I | awk '{print $1}'):8080"
