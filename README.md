# PrepperPi - Offline Knowledge Server

PrepperPi turns a Raspberry Pi into an offline knowledge server using Kiwix, serving Wikipedia, Stack Overflow, Project Gutenberg, and more over your local network.

## Requirements

- Raspberry Pi (3B+ or newer)
- Storage for ZIM content (NAS, USB drive, or large SD card)
- Network connection for initial content download

## Quick Start

```bash
git clone https://github.com/blakeai/prepperpi.git /opt/prepperpi
cp /opt/prepperpi/config/.env.example /opt/prepperpi/config/.env
# Edit config/.env with your settings
sudo bash /opt/prepperpi/scripts/install.sh
sudo bash /opt/prepperpi/scripts/update.sh
sudo bash /opt/prepperpi/scripts/start.sh
```

Access Kiwix at `http://<pi-ip>:8080`

## Configuration

All per-machine settings live in `config/.env` (gitignored). Copy from `config/.env.example`:

```bash
# Storage
STORAGE_PROFILE="minimal"    # minimal (~17GB), medium (~150GB), large (~512GB)
DOWNLOAD_LIMIT=""            # Bandwidth limit, e.g. "2M" for 2MB/s

# Network
PI_IP=""
SUBNET=""
WIFI_PSK=""

# System
PI_HOSTNAME="prepperpi"
PI_TIMEZONE="America/Chicago"
PI_LOCALE="en_US.UTF-8"

# Ports
KIWIX_PORT="8080"
WEBAPP_PORT="5001"

# Services (true/false)
ENABLE_KIWIX="true"
ENABLE_UPDATE_TIMER="true"
ENABLE_BACKUP_TIMER="false"
ENABLE_MONITOR="false"
```

### Storage Profiles

| Profile | Size | Contents |
|---------|------|----------|
| minimal | ~17GB | Wikipedia (top articles), based.cooking, army manuals |
| medium | ~150GB | Wikipedia (no images), Wikivoyage, Wiktionary, Stack Overflow, Ask Ubuntu, Super User, army manuals, based.cooking, anonymousplanet |
| large | ~512GB | Everything: full Wikipedia with images, Gutenberg (206GB), Stack Overflow, TED Talks, all Wikimedia projects, cheatography, army manuals, and more |

### NAS Storage

To store content on a NAS instead of the Pi's SD card, symlink the data directory before installing:

```bash
mkdir -p /mnt/nas/your-share/prepperpi/data
sudo mkdir -p /opt/prepperpi
sudo ln -s /mnt/nas/your-share/prepperpi/data /opt/prepperpi/data
```

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/install.sh` | Install kiwix-tools, systemd services, generate configs |
| `scripts/start.sh` | Start PrepperPi services |
| `scripts/stop.sh` | Stop PrepperPi services |
| `scripts/restart.sh` | Restart PrepperPi services |
| `scripts/status.sh` | Check service status |
| `scripts/update.sh` | Download/update ZIM content |
| `scripts/rebuild_kiwix_library.sh` | Rebuild Kiwix library.xml from ZIM files |
| `scripts/backup.sh` | Run backup |

### Content Management

```bash
# Download content based on storage profile
sudo bash scripts/update.sh

# Verify existing content
sudo bash scripts/update.sh verify

# Generate content report
sudo bash scripts/update.sh report

# Clean up temp files
sudo bash scripts/update.sh cleanup
```

## Services

The installer enables services based on your `.env` settings:

| Service | Default | Description |
|---------|---------|-------------|
| `prepperpi-kiwix` | enabled | Kiwix server |
| `prepperpi-update.timer` | enabled | Monthly content auto-update |
| `prepperpi-backup.timer` | disabled | Daily backups |
| `prepperpi-monitor` | disabled | System monitoring |

## File Structure

```
/opt/prepperpi/
├── config/
│   ├── .env              # Per-machine settings (gitignored)
│   ├── .env.example      # Template for .env
│   ├── kiwix.conf        # Content sources and profiles
│   ├── network.conf      # Network settings
│   └── system.conf       # System settings
├── scripts/              # Management scripts
├── systemd/              # Service definitions
├── configs/nginx/        # Nginx config template
├── data/ -> (symlink)    # Content storage (ZIM files, PDFs)
├── logs/                 # Logs
└── backup/               # Backups
```

## Troubleshooting

### Kiwix won't start
```bash
# Check if library.xml exists and has content
cat /opt/prepperpi/data/library.xml

# Rebuild it from ZIM files
sudo bash scripts/rebuild_kiwix_library.sh

# Check logs
sudo journalctl -u prepperpi-kiwix -n 20 --no-pager
```

### Content download failed
```bash
# Re-run; it skips already downloaded files
sudo bash scripts/update.sh

# Check disk space
df -h /opt/prepperpi/data/
```

## License

MIT
