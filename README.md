# PrepperPi - Offline Knowledge Server v2.0

PrepperPi transforms your Raspberry Pi into a powerful offline knowledge server, providing Wi-Fi hotspot functionality with access to Wikipedia, Stack Overflow, and other educational content without requiring internet connectivity.

## Features

- **Wi-Fi Hotspot**: Creates a secure Wi-Fi network for client devices
- **Offline Content**: Serves Wikipedia, Stack Overflow, and other ZIM archives via Kiwix
- **Modern Web Interface**: Responsive dashboard for system management
- **Real-time Monitoring**: CPU, memory, temperature, and network usage tracking
- **Automatic Updates**: Configurable content and system update schedules
- **Backup System**: Automated configuration and data backups
- **Security Features**: WPA3 support, MAC filtering, connection limits

## Hardware Requirements

- Raspberry Pi 4 (recommended) or Raspberry Pi 3B+
- MicroSD card (32GB+ recommended)
- Wi-Fi capability
- Ethernet connection (for initial setup and updates)

## Quick Installation

1. **Clone this repository**:
   `ash
   git clone https://github.com/YOUR_USERNAME/prepperpi.git
   sudo cp -r prepperpi /opt/
   `

2. **Run the installation script**:
   `ash
   cd /opt/prepperpi/scripts
   sudo bash install.sh
   `

3. **Reboot the system**:
   `ash
   sudo reboot
   `

4. **Connect to the Wi-Fi network**:
   - SSID: PrepperPi
   - Password: PrepperPi1234!

5. **Access the web interface**:
   - Open browser and go to http://prepperpi.local or http://10.10.0.1

## Configuration

### Network Settings

Edit /opt/prepperpi/config/network.conf:

`ash
SSID="PrepperPi"
PASSPHRASE="PrepperPi1234!"
COUNTRY="US"
SUBNET="10.10.0.0/24"
PI_IP="10.10.0.1"
`

### Content Sources

Edit /opt/prepperpi/config/kiwix.conf to add custom content sources:

`ash
CONTENT_SOURCES=(
    "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_maxi_2023-12.zim"
    "https://download.kiwix.org/zim/stack_exchange/stackoverflow.com_en_all_2023-12.zim"
)
`

## Web Interface

The modern web interface provides:

- **Dashboard**: System overview and quick actions
- **Status Page**: Detailed system monitoring and performance metrics
- **Settings**: Network, content, and security configuration
- **Content Management**: Manual updates and library management

## Services Management

PrepperPi uses systemd services for reliable operation:

`ash
# Check service status
sudo systemctl status prepperpi-kiwix
sudo systemctl status prepperpi-monitor

# Restart services
sudo systemctl restart prepperpi-kiwix
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq

# View logs
sudo journalctl -u prepperpi-kiwix -f
`

## Manual Operations

### Update Content
`ash
sudo /opt/prepperpi/scripts/update_content.sh
`

### Create Backup
`ash
sudo /opt/prepperpi/scripts/backup.sh
`

### System Information
`ash
python3 /opt/prepperpi/scripts/monitor.py
`

## Troubleshooting

### Wi-Fi Hotspot Not Working
1. Check hostapd status: sudo systemctl status hostapd
2. Verify configuration: sudo cat /etc/hostapd/hostapd.conf
3. Restart networking: sudo systemctl restart hostapd dnsmasq

### Kiwix Content Not Loading
1. Check Kiwix service: sudo systemctl status prepperpi-kiwix
2. Verify content files: ls -la /opt/prepperpi/data/kiwix/
3. Check library file: cat /opt/prepperpi/data/library.xml

### Web Interface Issues
1. Check nginx: sudo systemctl status nginx
2. Check Flask app logs: sudo journalctl -u prepperpi-monitor -f
3. View nginx logs: sudo tail -f /opt/prepperpi/logs/nginx_error.log

## File Structure

`
/opt/prepperpi/
config/          # Configuration files
scripts/         # Installation and management scripts
web/            # Web interface files
logs/           # System and application logs
backup/         # Automated backups
systemd/        # Service definitions
data/           # Kiwix content and library
`

## Security Considerations

- Change default Wi-Fi password immediately after installation
- Enable WPA3 if your clients support it
- Consider MAC address filtering for restricted access
- Regularly update system packages
- Monitor connected clients and usage

## Performance Optimization

- Use high-quality MicroSD card (Class 10, A2 rating recommended)
- Enable GPU memory split: sudo raspi-config â†’ Advanced Options
- Monitor temperature and ensure adequate cooling
- Optimize content selection based on available storage

## Contributing

PrepperPi is designed to be modular and extensible. Contributions welcome for:

- Additional content sources and formats
- Enhanced monitoring and alerting
- Mobile app development
- Multi-language support
- Hardware integration (displays, sensors)

## License

This project is released under the MIT License. See LICENSE file for details.

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review system logs in /opt/prepperpi/logs/
3. Create an issue on GitHub with system information and logs

## Version History

- **v2.0**: Complete rewrite with modern web interface, enhanced monitoring, security improvements
- **v1.0**: Basic hotspot and Kiwix integration

---

**PrepperPi** - Making knowledge accessible anywhere, anytime.
