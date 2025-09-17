## /opt/prepperpi/scripts/install.sh

#!/usr/bin/env bash
set -euo pipefail

# === PrepperPi Install Script (Full) ===
# Raspberry Pi OS (Bookworm) 64-bit recommended

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

SSID="${SSID:-PrepperPi}"
WPA_PASSPHRASE="${WPA_PASSPHRASE:-PrepperPi1234!}"
COUNTRY_CODE="${COUNTRY_CODE:-US}"
HOTSPOT_IP="${HOTSPOT_IP:-10.10.0.1}"
WLAN_DEV="${WLAN_DEV:-wlan0}"
LAN_UPLINK_DEV="${LAN_UPLINK_DEV:-eth0}"
LIB_ROOT="/mnt/library"
APP_ROOT="/opt/prepperpi"

echo "[1/12] Install packages"
apt-get update
apt-get install -y --no-install-recommends \
  hostapd dnsmasq rfkill iw iptables \
  nginx python3-venv python3-pip \
  unzip curl aria2 jq ca-certificates \
  avahi-daemon dhcpcd5 git vim tmux \
  unattended-upgrades kiwix-tools || true

systemctl enable --now avahi-daemon

echo "[2/12] Create user + dirs"
id -u prepperpi >/dev/null 2>&1 || useradd -m -s /bin/bash prepperpi
mkdir -p "$LIB_ROOT" /var/log/prepperpi
chown -R prepperpi:prepperpi "$LIB_ROOT" /var/log/prepperpi

echo "[3/12] Web app venv"
install -d -o prepperpi -g prepperpi "$APP_ROOT"
cp -r ../webapp "$APP_ROOT/"
python3 -m venv "$APP_ROOT/venv"
source "$APP_ROOT/venv/bin/activate"
pip install --upgrade pip wheel
pip install flask waitress
deactivate
chown -R prepperpi:prepperpi "$APP_ROOT"

echo "[4/12] Hotspot configs"
install -Dm0644 ../configs/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
install -Dm0644 ../configs/dnsmasq/dnsmasq.conf /etc/dnsmasq.d/prepperpi.conf
sed -i "s/^ssid=.*/ssid=${SSID}/" /etc/hostapd/hostapd.conf
sed -i "s/^wpa_passphrase=.*/wpa_passphrase=${WPA_PASSPHRASE}/" /etc/hostapd/hostapd.conf
sed -i "s/^country_code=.*/country_code=${COUNTRY_CODE}/" /etc/hostapd/hostapd.conf

if ! grep -q "interface ${WLAN_DEV}" /etc/dhcpcd.conf; then
cat >> /etc/dhcpcd.conf <<EOF

# PrepperPi hotspot
interface ${WLAN_DEV}
static ip_address=${HOTSPOT_IP}/24
nohook wpa_supplicant
EOF
fi

sed -i "s/^#dhcp-range=.*/dhcp-range=${HOTSPOT_IP%.*}.50,${HOTSPOT_IP%.*}.150,12h/" /etc/dnsmasq.d/prepperpi.conf

echo "[5/12] Enable IP forwarding + NAT"
sysctl -w net.ipv4.ip_forward=1
grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
install -Dm0755 ../scripts/apply_nat.sh /opt/prepperpi/scripts/apply_nat.sh
install -Dm0644 ../configs/systemd/nat-iptables.service /etc/systemd/system/nat-iptables.service
systemctl enable nat-iptables.service
systemctl start nat-iptables.service

echo "[6/12] Nginx config"
install -Dm0644 ../configs/nginx/prepperpi.conf /etc/nginx/sites-available/prepperpi.conf
ln -sf /etc/nginx/sites-available/prepperpi.conf /etc/nginx/sites-enabled/prepperpi.conf
rm -f /etc/nginx/sites-enabled/default || true
nginx -t && systemctl restart nginx

echo "[7/12] Kiwix + Web UI services"
install -Dm0644 ../configs/systemd/kiwix-serve.service /etc/systemd/system/kiwix-serve.service
install -Dm0644 ../configs/systemd/prepperpi-web.service /etc/systemd/system/prepperpi-web.service
install -Dm0755 ../scripts/rebuild_kiwix_library.sh /opt/prepperpi/scripts/rebuild_kiwix_library.sh
systemctl daemon-reload
systemctl enable kiwix-serve.service prepperpi-web.service
systemctl restart kiwix-serve.service || true
systemctl restart prepperpi-web.service

echo "[8/12] Content update (manual)"
install -Dm0755 ../scripts/update.sh /opt/prepperpi/scripts/update.sh
install -Dm0644 ../manifests/update_manifest.json /opt/prepperpi/manifests/update_manifest.json
install -Dm0644 ../configs/systemd/prepperpi-update.service /etc/systemd/system/prepperpi-update.service
install -Dm0644 ../configs/systemd/prepperpi-update.timer /etc/systemd/system/prepperpi-update.timer
# Timer intentionally NOT enabled (manual updates)

echo "[9/12] OS updates on boot + weekly check"
install -Dm0644 ../configs/systemd/os-update-onboot.service /etc/systemd/system/os-update-onboot.service
install -Dm0644 ../configs/systemd/os-update-weekly.service /etc/systemd/system/os-update-weekly.service
install -Dm0644 ../configs/systemd/os-update-weekly.timer /etc/systemd/system/os-update-weekly.timer
systemctl enable os-update-onboot.service
systemctl enable --now os-update-weekly.timer

echo "[10/12] Enable hotspot"
systemctl unmask hostapd || true
systemctl enable hostapd dnsmasq dhcpcd
systemctl restart hostapd dnsmasq dhcpcd

echo "[11/12] Reminder"
echo "Put ZIMs in /mnt/library/10_Wikipedia_ZIM, then:"
echo "sudo -u prepperpi /opt/prepperpi/scripts/rebuild_kiwix_library.sh && sudo systemctl restart kiwix-serve.service"

echo "[12/12] Done. Connect to Wi-Fi '${SSID}' and browse http://${HOTSPOT_IP}/"
