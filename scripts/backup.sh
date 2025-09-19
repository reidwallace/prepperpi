#!/bin/bash
# PrepperPi Backup Script

set -euo pipefail

BACKUP_DIR="/opt/prepperpi/backup"
LOG_FILE="/opt/prepperpi/logs/backup.log"
RETENTION_DAYS=7

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create backup directory structure
backup_date=$(date +%Y%m%d_%H%M%S)
backup_path="$BACKUP_DIR/backup_$backup_date"
mkdir -p "$backup_path"

log "Starting backup to $backup_path"

# Backup configuration files
log "Backing up configuration files..."
cp -r /opt/prepperpi/config "$backup_path/"

# Backup web interface
log "Backing up web interface..."
cp -r /var/www/html "$backup_path/"

# Backup system configuration
log "Backing up system configuration..."
mkdir -p "$backup_path/system"
cp /etc/hostapd/hostapd.conf "$backup_path/system/" 2>/dev/null || true
cp /etc/dnsmasq.conf "$backup_path/system/" 2>/dev/null || true
cp /etc/dhcpcd.conf "$backup_path/system/" 2>/dev/null || true

# Backup logs (last 7 days)
log "Backing up recent logs..."
mkdir -p "$backup_path/logs"
find /opt/prepperpi/logs -name "*.log" -mtime -7 -exec cp {} "$backup_path/logs/" \;

# Create backup info file
cat > "$backup_path/backup_info.txt" << EOF
PrepperPi Backup Information
Created: $(date)
Hostname: $(hostname)
OS Version: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
Uptime: $(uptime -p)
EOF

# Compress backup
log "Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "backup_$backup_date.tar.gz" "backup_$backup_date"
rm -rf "backup_$backup_date"

# Cleanup old backups
log "Cleaning up old backups..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

log "Backup completed successfully"
