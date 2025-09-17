#!/usr/bin/env bash
set -euo pipefail
WLAN_DEV="wlan0"
LAN_DEV="eth0"
iptables -t nat -F
iptables -F FORWARD || true
iptables -t nat -A POSTROUTING -o "$LAN_DEV" -j MASQUERADE
iptables -A FORWARD -i "$LAN_DEV" -o "$WLAN_DEV" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "$WLAN_DEV" -o "$LAN_DEV" -j ACCEPT
echo "NAT applied"
