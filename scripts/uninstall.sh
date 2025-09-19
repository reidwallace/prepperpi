#!/usr/bin/env bash
# Uninstaller skeleton for PrepperPi (keeps data/ by default)
set -euo pipefail

read -p "This will stop/disable services but keep data/. Continue? [y/N] " ans
if [[ "${ans:-N}" != "y" && "${ans:-N}" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

if systemctl list-unit-files | grep -q kiwix-serve; then
  sudo systemctl stop kiwix-serve || true
  sudo systemctl disable kiwix-serve || true
fi

echo "Uninstall finished. You may remove /opt/prepperpi manually if desired."
