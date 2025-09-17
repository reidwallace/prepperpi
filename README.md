<<<<<<< HEAD
# prepperpi
Offline knowledge server for Raspberry Pi — Wi-Fi hotspot with Kiwix, web UI, and manual/automatic update options.
=======
# PrepperPi Setup Bundle (Full)

This bundle sets up a Raspberry Pi as an **offline Wi-Fi hotspot** with:
- Nginx reverse proxy
- Kiwix offline server (at `/kiwix/`)
- A small web UI (home page + **manual update** button)
- **Manual** content updates via manifest
- **OS updates**: run on boot and **weekly check** (logs only)

## Defaults
- SSID: `PrepperPi`
- Passphrase: `PrepperPi1234!`
- Country: `US`
- Subnet: `10.10.0.0/24` (Pi at `10.10.0.1`)

## Quick Start
1) Copy this folder to the Pi at `/opt/prepperpi` and run:
   ```bash
   cd /opt/prepperpi/scripts
   sudo bash install.sh
>>>>>>> 65cd149 (Initial upload of PrepperPi setup bundle)
