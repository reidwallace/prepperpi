#!/usr/bin/env python3
"""
PrepperPi System Monitor
Monitors system health and logs statistics
"""

import time
import json
import psutil
import subprocess
import logging
from datetime import datetime
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/opt/prepperpi/logs/monitor.log"),
        logging.StreamHandler(),
    ],
)


class SystemMonitor:
    def __init__(self):
        self.stats_file = Path("/opt/prepperpi/logs/system_stats.json")
        self.alert_thresholds = {
            "cpu_percent": 80,
            "memory_percent": 85,
            "disk_percent": 90,
            "temperature": 75,
        }

    def get_system_stats(self):
        """Collect current system statistics"""
        stats = {
            "timestamp": datetime.now().isoformat(),
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory": dict(psutil.virtual_memory()._asdict()),
            "disk": dict(psutil.disk_usage("/")._asdict()),
            "network": self.get_network_stats(),
            "temperature": self.get_cpu_temperature(),
            "connected_clients": self.get_connected_clients(),
        }

        return stats

    def get_network_stats(self):
        """Get network interface statistics"""
        try:
            stats = psutil.net_io_counters(pernic=True)
            wlan_stats = stats.get("wlan0", None)
            if wlan_stats:
                return {
                    "bytes_sent": wlan_stats.bytes_sent,
                    "bytes_recv": wlan_stats.bytes_recv,
                    "packets_sent": wlan_stats.packets_sent,
                    "packets_recv": wlan_stats.packets_recv,
                }
        except:
            pass
        return {}

    def get_cpu_temperature(self):
        """Get CPU temperature"""
        try:
            result = subprocess.run(["vcgencmd", "measure_temp"], capture_output=True, text=True)
            if result.returncode == 0:
                temp_str = result.stdout.strip()
                temp = float(temp_str.split("=")[1].split("'")[0])
                return temp
        except:
            pass
        return None

    def get_connected_clients(self):
        """Count connected WiFi clients"""
        try:
            result = subprocess.run(
                ["iw", "dev", "wlan0", "station", "dump"],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                # Count "Station" entries
                return result.stdout.count("Station ")
        except:
            pass
        return 0

    def check_alerts(self, stats):
        """Check for alert conditions"""
        alerts = []

        if stats["cpu_percent"] > self.alert_thresholds["cpu_percent"]:
            alerts.append(f"High CPU usage: {stats['cpu_percent']:.1f}%")

        memory_percent = stats["memory"]["percent"]
        if memory_percent > self.alert_thresholds["memory_percent"]:
            alerts.append(f"High memory usage: {memory_percent:.1f}%")

        disk_percent = (stats["disk"]["used"] / stats["disk"]["total"]) * 100
        if disk_percent > self.alert_thresholds["disk_percent"]:
            alerts.append(f"High disk usage: {disk_percent:.1f}%")

        if stats["temperature"] and stats["temperature"] > self.alert_thresholds["temperature"]:
            alerts.append(f"High temperature: {stats['temperature']:.1f}Â°C")

        return alerts

    def save_stats(self, stats):
        """Save statistics to file"""
        try:
            # Load existing stats
            if self.stats_file.exists():
                with open(self.stats_file, "r") as f:
                    all_stats = json.load(f)
            else:
                all_stats = []

            # Add new stats
            all_stats.append(stats)

            # Keep only last 1000 entries
            if len(all_stats) > 1000:
                all_stats = all_stats[-1000:]

            # Save back to file
            with open(self.stats_file, "w") as f:
                json.dump(all_stats, f, indent=2)
        except Exception as e:
            logging.error(f"Failed to save stats: {e}")

    def run(self):
        """Main monitoring loop"""
        logging.info("PrepperPi System Monitor started")

        while True:
            try:
                stats = self.get_system_stats()
                alerts = self.check_alerts(stats)

                # Log basic stats
                logging.info(
                    f"CPU: {stats['cpu_percent']:.1f}%, "
                    f"Memory: {stats['memory']['percent']:.1f}%, "
                    f"Clients: {stats['connected_clients']}"
                )

                # Log alerts
                for alert in alerts:
                    logging.warning(alert)

                # Save stats
                self.save_stats(stats)

                # Wait before next check
                time.sleep(60)  # Check every minute

            except KeyboardInterrupt:
                logging.info("Monitor stopped by user")
                break
            except Exception as e:
                logging.error(f"Monitor error: {e}")
                time.sleep(60)


if __name__ == "__main__":
    monitor = SystemMonitor()
    monitor.run()
