#!/usr/bin/env bash
set -euo pipefail
echo "[+] Restarting PrepperPi services..."
systemctl restart prepperpi-kiwix
echo "[+] PrepperPi running at http://$(hostname -I | awk '{print $1}'):8080"
