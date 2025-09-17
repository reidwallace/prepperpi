# PrepperPi - Offline Knowledge Server v2.0

![PrepperPi Logo](https://img.shields.io/badge/PrepperPi-v2.0-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi-red)

PrepperPi transforms your Raspberry Pi into a powerful offline knowledge server, providing Wi-Fi hotspot functionality with access to Wikipedia, Stack Overflow, medical resources, survival manuals, and other essential content without requiring internet connectivity.

## 🌟 Features

- **📡 Wi-Fi Hotspot**: Creates a secure Wi-Fi network for client devices
- **📚 Comprehensive Offline Content**: Wikipedia, medical resources, survival manuals, literature, and educational content
- **🖥️ Modern Web Interface**: Responsive dashboard for system management
- **📊 Real-time Monitoring**: CPU, memory, temperature, and network usage tracking
- **🔄 Automatic Updates**: Configurable content and system update schedules
- **💾 Backup System**: Automated configuration and data backups
- **🔒 Security Features**: WPA3 support, MAC filtering, connection limits
- **📱 Mobile-Friendly**: Responsive design works on phones, tablets, and laptops

## 📋 Hardware Requirements

- **Raspberry Pi 4** (recommended) or **Raspberry Pi 3B+**
- **MicroSD card** 32GB minimum, 64GB+ recommended
- **Wi-Fi capability** (built-in on Pi 3B+ and Pi 4)
- **Ethernet connection** (for initial setup and content updates)

## 🚀 Quick Installation

### Step 1: Download and Setup
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/prepperpi.git

# Copy to system directory
sudo cp -r prepperpi /opt/

# Navigate to scripts directory
cd /opt/prepperpi/scripts
```

### Step 2: Run Installation
```bash
# Make install script executable
sudo chmod +x install.sh

# Run the installation (this will take 10-15 minutes)
sudo bash install.sh
```

### Step 3: Reboot and Connect
```bash
# Reboot to activate all services
sudo reboot
```

After reboot:
1. **Connect to Wi-Fi**: Look for `PrepperPi` network
2. **Password**: `PrepperPi1234!`
3. **Access Web Interface**: Open browser to `http://prepperpi.local` or `http://10.10.0.1`

## ⚙️ Configuration

### Network Settings

Edit `/opt/prepperpi/config/network.conf`:

```bash
SSID="PrepperPi"
PASSPHRASE="PrepperPi1234!"
COUNTRY="US"
SUBNET="10.10.0.0/24"
PI_IP="10.10.0.1"
```

**⚠️ Important**: Change the default password immediately after installation!

### Content Configuration

PrepperPi includes three storage profiles in `/opt/prepperpi/config/kiwix.conf`:

#### Minimal Profile (32GB SD Card)
- Wikipedia (top articles)
- WikiMed (medical content)
- Project Gutenberg (selection)
- WikiHow (how-to guides)

#### Standard Profile (64GB SD Card) - **Default**
- Wikipedia (no pictures, 20GB)
- Wikivoyage (travel guides)
- Wiktionary (dictionary)
- WikiMed (medical resources)
- Project Gutenberg (book selection)
- Stack Overflow (programming Q&A)
- Khan Academy (educational content)
- WikiHow (practical guides)

#### Large Profile (128GB+ Storage)
- Complete Wikipedia with images (95GB)
- All Wikimedia projects
- Complete Project Gutenberg library
- Multiple Stack Exchange sites
- TED Talks
- Comprehensive educational content

To change profiles, edit the `STORAGE_PROFILE` setting:
```bash
STORAGE_PROFILE="large"    # or "minimal" or "standard"
```

## 🖥️ Web Interface

The modern web interface provides:

- **🏠 Dashboard**: System overview and quick actions
- **📈 Status Page**: Real-time system monitoring and performance metrics
- **⚙️ Settings**: Network, content, and security configuration  
- **📚 Content Management**: Manual updates and library management
- **📖 Knowledge Library**: Direct access to offline content via Kiwix

## 🔧 Services Management

PrepperPi uses systemd services for reliable operation:

### Check Service Status
```bash
sudo systemctl status prepperpi-kiwix
sudo systemctl status prepperpi-monitor
sudo systemctl status hostapd
sudo systemctl status dnsmasq
sudo systemctl status nginx
```

### Restart Services
```bash
sudo systemctl restart prepperpi-kiwix
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq
sudo systemctl restart nginx
```

### View Service Logs
```bash
# Kiwix server logs
sudo journalctl -u prepperpi-kiwix -f

# System monitor logs
sudo journalctl -u prepperpi-monitor -f

# All PrepperPi logs
sudo tail -f /opt/prepperpi/logs/*.log
```

## 🛠️ Manual Operations

### Update Content
```bash
# Update all content sources
sudo /opt/prepperpi/scripts/update_content.sh

# Verify existing content integrity
sudo /opt/prepperpi/scripts/update_content.sh verify

# Generate content report
sudo /opt/prepperpi/scripts/update_content.sh report
```

### System Backup
```bash
# Create system backup
sudo /opt/prepperpi/scripts/backup.sh

# View backup location
ls -la /opt/prepperpi/backup/
```

### System Information
```bash
# Get comprehensive system stats
python3 /opt/prepperpi/scripts/monitor.py

# Verify installation
sudo /opt/prepperpi/scripts/verify_install.sh
```

## 🗂️ File Structure

```
/opt/prepperpi/
├── config/              # Configuration files
│   ├── network.conf     # Network settings
│   ├── kiwix.conf      # Content sources
│   ├── system.conf     # System settings
│   └── nginx.conf      # Web server config
├── scripts/            # Management scripts
│   ├── install.sh      # Main installer
│   ├── update_content.sh # Content manager
│   ├── backup.sh       # Backup system
│   ├── monitor.py      # System monitor
│   └── verify_install.sh # Installation verification
├── web/               # Web interface
│   ├── app.py         # Flask application
│   ├── static/        # CSS, JavaScript, images
│   └── templates/     # HTML templates
├── systemd/           # Service definitions
├── logs/             # System and application logs
├── backup/           # Automated backups
└── data/             # Content storage
    ├── kiwix/        # ZIM files
    ├── pdfs/         # PDF documents
    └── maps/         # Offline maps
```

## 🩺 Troubleshooting

### Wi-Fi Hotspot Not Working

1. **Check hostapd status**:
   ```bash
   sudo systemctl status hostapd
   ```

2. **Verify configuration**:
   ```bash
   sudo cat /etc/hostapd/hostapd.conf
   ```

3. **Restart networking services**:
   ```bash
   sudo systemctl restart hostapd dnsmasq
   ```

4. **Check for interference**:
   ```bash
   iwlist scan | grep -E "ESSID|Channel"
   ```

### Kiwix Content Not Loading

1. **Check Kiwix service**:
   ```bash
   sudo systemctl status prepperpi-kiwix
   ```

2. **Verify content files**:
   ```bash
   ls -la /opt/prepperpi/data/kiwix/
   ```

3. **Check library file**:
   ```bash
   cat /opt/prepperpi/data/library.xml
   ```

4. **Restart Kiwix service**:
   ```bash
   sudo systemctl restart prepperpi-kiwix
   ```

### Web Interface Issues

1. **Check nginx status**:
   ```bash
   sudo systemctl status nginx
   ```

<<<<<<< HEAD
2. **Check Flask application**:
   ```bash
   sudo systemctl status prepperpi-monitor
   ```
=======
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
>>>>>>> 685c56559e3db77be73d60da282d8ee04020e068

3. **View error logs**:
   ```bash
   sudo tail -f /opt/prepperpi/logs/nginx_error.log
   sudo tail -f /opt/prepperpi/logs/system.log
   ```

### Performance Issues

1. **Monitor system resources**:
   - Access status page at `http://prepperpi.local/status`
   - Check CPU temperature: `vcgencmd measure_temp`
   - Monitor disk usage: `df -h`

2. **Optimize performance**:
   ```bash
   # Increase GPU memory split
   sudo raspi-config
   # Advanced Options → Memory Split → 128
   
   # Check for thermal throttling
   vcgencmd get_throttled
   ```

### Storage Issues

1. **Check available space**:
   ```bash
   df -h /opt/prepperpi/data/
   ```

2. **Clean up old content**:
   ```bash
   sudo /opt/prepperpi/scripts/update_content.sh cleanup
   ```

3. **Change storage profile**:
   Edit `/opt/prepperpi/config/kiwix.conf` and change `STORAGE_PROFILE`

## 📦 Content Sources

PrepperPi includes content from these trusted sources:

### Core Knowledge
- **Wikipedia**: Complete offline encyclopedia
- **Wikivoyage**: Travel and location guides
- **Wiktionary**: Comprehensive dictionary
- **Wikibooks**: Educational textbooks

### Medical & Health
- **WikiMed**: Curated medical encyclopedia
- **WHO Manuals**: World Health Organization resources
- **Red Cross Guides**: First aid and emergency response
- **CDC Resources**: Disease control and prevention

### Literature & Books
- **Project Gutenberg**: 70,000+ public domain books
- **Internet Archive**: Additional book collections

### Technical Resources
- **Stack Overflow**: Programming questions and answers
- **Ask Ubuntu**: Linux and Ubuntu support
- **Super User**: Computer troubleshooting

### Educational Content
- **Khan Academy**: Complete K-12 curriculum
- **TED Talks**: Educational and inspirational videos
- **WikiHow**: Practical how-to guides

### Survival & Preparedness
- **U.S. Army Survival Manual (FM 21-76)**
- **Military Field Manuals**
- **Emergency Preparedness Guides**
- **First Aid and Medical Emergency Resources**

## 🔒 Security Considerations

### Essential Security Steps

1. **Change default credentials immediately**:
   ```bash
   sudo nano /opt/prepperpi/config/network.conf
   # Change SSID and PASSPHRASE
   ```

2. **Enable WPA3 if supported**:
   ```bash
   # Edit network.conf
   ENABLE_WPA3=true
   ```

3. **Set up MAC filtering** (optional):
   ```bash
   ENABLE_MAC_FILTERING=true
   ```

4. **Regular updates**:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

5. **Monitor connected devices**:
   - Check status page for connected clients
   - Review logs regularly

### Network Security
- Default configuration creates isolated network (10.10.0.0/24)
- No internet bridging by default
- Configurable connection limits
- Optional MAC address filtering

## ⚡ Performance Optimization

### Recommended Hardware Setup
- **High-quality MicroSD card**: Class 10, A2 rating minimum
- **Adequate cooling**: Heatsinks or fan for continuous operation
- **Stable power supply**: Official Pi power adapter recommended

### System Optimization
```bash
# Increase GPU memory split for better performance
sudo raspi-config
# Advanced Options → Memory Split → 128

# Enable file system optimizations
sudo nano /boot/cmdline.txt
# Add: fsck.repair=yes

# Optimize for SD card longevity
echo 'tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0' | sudo tee -a /etc/fstab
```

### Content Optimization
- Choose appropriate storage profile for your SD card size
- Enable compression for older content
- Regular cleanup of temporary files
- Monitor storage usage via web interface

## 🤝 Contributing

PrepperPi is designed to be modular and extensible. Contributions welcome for:

- **Additional content sources** and formats
- **Enhanced monitoring** and alerting features
- **Mobile app** development
- **Multi-language support**
- **Hardware integration** (displays, sensors, GPS)
- **Mesh networking** capabilities
- **Educational curricula** integration

### Development Setup
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/prepperpi.git
cd prepperpi

# Create development branch
git checkout -b feature/your-feature-name

# Make changes and test

# Submit pull request
```

## 📄 License

This project is released under the **MIT License**. See [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help

1. **Check troubleshooting section** above
2. **Review system logs**: `/opt/prepperpi/logs/`
3. **Run verification script**: `sudo /opt/prepperpi/scripts/verify_install.sh`
4. **Create GitHub issue** with:
   - System information (`uname -a`)
   - Error logs
   - Steps to reproduce issue

### Community Resources
- **GitHub Issues**: Bug reports and feature requests
- **Wiki**: Additional documentation and guides
- **Discussions**: Community support and ideas

## 📈 Version History

### v2.0 (Current)
- Complete rewrite with modern web interface
- Enhanced security and monitoring
- Comprehensive content sources (medical, survival, educational)
- Smart content management and verification
- Mobile-responsive design
- Automated backup system
- Professional logging and error handling

### v1.0
- Basic hotspot functionality
- Simple Kiwix integration
- Command-line management

---

## 🏁 Quick Start Summary

1. **Clone repo**: `git clone https://github.com/YOUR_USERNAME/prepperpi.git`
2. **Install**: `sudo cp -r prepperpi /opt/ && cd /opt/prepperpi/scripts && sudo bash install.sh`
3. **Reboot**: `sudo reboot`
4. **Connect**: Wi-Fi "PrepperPi" with password "PrepperPi1234!"
5. **Browse**: Visit `http://prepperpi.local`
6. **Secure**: Change default password in settings!

**PrepperPi** - Making knowledge accessible anywhere, anytime. 📡📚

---

*Built with ❤️ for emergency preparedness, education, and offline knowledge preservation.*