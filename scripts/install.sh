#!/bin/bash
set -euo pipefail

# PrepperPi Installation Script v2.0
# Enhanced with error handling, logging, and rollback functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/opt/prepperpi/logs/install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

info() {
    log "${BLUE}INFO: $1${NC}"
}

warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    local percent=$((current * 100 / total))
    printf "\r${BLUE}[%3d%%]${NC} %s" "$percent" "$description"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

# System requirements check
check_requirements() {
    info "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Raspberry Pi OS" /etc/os-release 2>/dev/null; then
        warning "This script is optimized for Raspberry Pi OS"
    fi
    
    # Check available disk space (minimum 4GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 4194304 ]]; then
        error_exit "Insufficient disk space. At least 4GB required."
    fi
    
    # Check RAM (minimum 1GB)
    total_ram=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_ram -lt 900 ]]; then
        error_exit "Insufficient RAM. At least 1GB recommended."
    fi
    
    # Check internet connection
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error_exit "No internet connection. Required for downloading packages."
    fi
    
    success "System requirements check passed"
}

# Backup existing configuration
backup_config() {
    info "Creating configuration backup..."
    
    local backup_dir="/opt/prepperpi/backup/pre-install-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup important system files
    [[ -f /etc/hostapd/hostapd.conf ]] && cp /etc/hostapd/hostapd.conf "$backup_dir/"
    [[ -f /etc/dnsmasq.conf ]] && cp /etc/dnsmasq.conf "$backup_dir/"
    [[ -f /etc/dhcpcd.conf ]] && cp /etc/dhcpcd.conf "$backup_dir/"
    
    success "Configuration backed up to $backup_dir"
}

# Install dependencies
install_dependencies() {
    local total_steps=8
    local current_step=0
    
    info "Installing dependencies..."
    
    show_progress $((++current_step)) $total_steps "Updating package list"
    apt-get update -qq || error_exit "Failed to update package list"
    
    show_progress $((++current_step)) $total_steps "Installing hostapd"
    apt-get install -y hostapd || error_exit "Failed to install hostapd"
    
    show_progress $((++current_step)) $total_steps "Installing dnsmasq"
    apt-get install -y dnsmasq || error_exit "Failed to install dnsmasq"
    
    show_progress $((++current_step)) $total_steps "Installing nginx"
    apt-get install -y nginx || error_exit "Failed to install nginx"
    
    show_progress $((++current_step)) $total_steps "Installing kiwix-tools"
    apt-get install -y kiwix-tools || error_exit "Failed to install kiwix-tools"
    
    show_progress $((++current_step)) $total_steps "Installing Python dependencies"
    apt-get install -y python3-pip python3-flask || error_exit "Failed to install Python dependencies"
    
    show_progress $((++current_step)) $total_steps "Installing monitoring tools"
    apt-get install -y htop iotop || error_exit "Failed to install monitoring tools"
    
    show_progress $((++current_step)) $total_steps "Installing additional utilities"
    apt-get install -y curl wget unzip || error_exit "Failed to install utilities"
    
    echo # New line after progress
    success "All dependencies installed"
}

# Configure services
configure_services() {
    info "Configuring services..."
    
    # Load configuration
    source "$BASE_DIR/config/network.conf"
    source "$BASE_DIR/config/kiwix.conf"
    source "$BASE_DIR/config/system.conf"
    
    # Configure hostapd
    cat > /etc/hostapd/hostapd.conf << EOF
interface=$WIFI_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
country_code=$COUNTRY
EOF

    # Configure dnsmasq
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    cat > /etc/dnsmasq.conf << EOF
interface=$WIFI_INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
address=/prepperpi.local/$PI_IP
EOF

    # Configure dhcpcd
    cat >> /etc/dhcpcd.conf << EOF
interface $WIFI_INTERFACE
static ip_address=$PI_IP/24
nohook wpa_supplicant
EOF

    success "Services configured"
}

# Install systemd services
install_systemd_services() {
    info "Installing systemd services..."
    
    cp "$BASE_DIR/systemd/"*.service /etc/systemd/system/
    systemctl daemon-reload
    
    # Enable services
    systemctl enable prepperpi-kiwix.service
    systemctl enable prepperpi-monitor.service
    systemctl enable prepperpi-backup.service
    
    success "Systemd services installed and enabled"
}

# Install web interface
install_web_interface() {
    info "Installing web interface..."
    
    # Copy web files
    cp -r "$BASE_DIR/web/"* /var/www/html/
    
    # Configure nginx
    cp "$BASE_DIR/config/nginx.conf" /etc/nginx/sites-available/prepperpi
    ln -sf /etc/nginx/sites-available/prepperpi /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Set permissions
    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/
    
    success "Web interface installed"
}

# Main installation function
main() {
    log "Starting PrepperPi installation..."
    
    check_root
    check_requirements
    backup_config
    install_dependencies
    configure_services
    install_systemd_services
    install_web_interface
    
    success "PrepperPi installation completed successfully!"
    info "Reboot required to activate all services"
    info "After reboot, connect to SSID: $SSID with password: $PASSPHRASE"
    info "Access web interface at: http://prepperpi.local or http://$PI_IP"
}

# Error handling
trap 'error_exit "Installation failed at line $LINENO"' ERR

# Run installation
main "$@"
