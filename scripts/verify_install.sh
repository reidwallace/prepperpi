#!/bin/bash
# PrepperPi Installation Verification Script

echo "PrepperPi Installation Verification"
echo "==================================="

# Check if all required directories exist
echo "Checking directory structure..."
dirs=(
    "/opt/prepperpi/config"
    "/opt/prepperpi/scripts"
    "/opt/prepperpi/web"
    "/opt/prepperpi/logs"
    "/opt/prepperpi/backup"
    "/opt/prepperpi/systemd"
)

for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "âœ“ $dir exists"
    else
        echo "âœ— $dir missing"
    fi
done

# Check configuration files
echo -e "\nChecking configuration files..."
configs=(
    "/opt/prepperpi/config/network.conf"
    "/opt/prepperpi/config/kiwix.conf"
    "/opt/prepperpi/config/system.conf"
)

for config in "${configs[@]}"; do
    if [[ -f "$config" ]]; then
        echo "âœ“ $config exists"
    else
        echo "âœ— $config missing"
    fi
done

# Check systemd services
echo -e "\nChecking systemd services..."
services=(
    "prepperpi-kiwix.service"
    "prepperpi-monitor.service"
    "prepperpi-backup.service"
)

for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        echo "âœ“ $service installed"
    else
        echo "âœ— $service not found"
    fi
done

echo -e "\nInstallation verification complete."
