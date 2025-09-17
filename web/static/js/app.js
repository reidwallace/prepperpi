// PrepperPi Web Interface JavaScript

class PrepperPi {
    constructor() {
        this.init();
        this.startPeriodicUpdates();
    }

    init() {
        console.log('PrepperPi Web Interface initialized');
        this.updateSystemStats();
    }

    async updateSystemStats() {
        try {
            const response = await fetch('/api/system/stats');
            const stats = await response.json();
            
            if (stats.error) {
                console.error('Stats error:', stats.error);
                return;
            }

            this.displayStats(stats);
        } catch (error) {
            console.error('Failed to fetch system stats:', error);
            this.displayError();
        }
    }

    displayStats(stats) {
        // Update CPU usage
        const cpuElement = document.getElementById('cpu-usage');
        if (cpuElement && stats.cpu_percent !== undefined) {
            cpuElement.textContent = ${stats.cpu_percent.toFixed(1)}%;
            cpuElement.className = this.getStatusClass(stats.cpu_percent, 80);
        }

        // Update memory usage
        const memoryElement = document.getElementById('memory-usage');
        if (memoryElement && stats.memory) {
            const memPercent = stats.memory.percent;
            memoryElement.textContent = ${memPercent.toFixed(1)}%;
            memoryElement.className = this.getStatusClass(memPercent, 85);
        }

        // Update connected clients
        const clientElement = document.getElementById('client-count');
        if (clientElement && stats.connected_clients !== undefined) {
            clientElement.textContent = stats.connected_clients.toString();
        }

        // Update temperature
        const tempElement = document.getElementById('temperature');
        if (tempElement && stats.temperature) {
            tempElement.textContent = ${stats.temperature.toFixed(1)}Â°C;
            tempElement.className = this.getStatusClass(stats.temperature, 75);
        }

        // Update uptime (if available)
        const uptimeElement = document.getElementById('uptime');
        if (uptimeElement) {
            // This would need to be calculated server-side
            uptimeElement.textContent = 'Available in status page';
        }
    }

    getStatusClass(value, threshold) {
        if (value > threshold) {
            return 'status-warning';
        } else if (value > threshold * 1.1) {
            return 'status-offline';
        }
        return 'status-online';
    }

    displayError() {
        const elements = ['cpu-usage', 'memory-usage', 'client-count', 'temperature', 'uptime'];
        elements.forEach(id => {
            const element = document.getElementById(id);
            if (element) {
                element.textContent = 'Error';
                element.className = 'status-offline';
            }
        });
    }

    startPeriodicUpdates() {
        // Update stats every 30 seconds
        setInterval(() => {
            this.updateSystemStats();
        }, 30000);
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = 
otification notification-;
        notification.innerHTML = 
            <span></span>
            <button onclick="this.parentElement.remove()">Ã—</button>
        ;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }
}

// Global functions
async function updateContent() {
    try {
        const button = event.target;
        const originalText = button.innerHTML;
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Updating...';
        button.disabled = true;

        const response = await fetch('/api/content/update', {
            method: 'POST'
        });
        
        const result = await response.json();
        
        if (result.success) {
            app.showNotification('Content update started successfully', 'success');
        } else {
            app.showNotification('Failed to start content update: ' + result.error, 'error');
        }
    } catch (error) {
        app.showNotification('Error: ' + error.message, 'error');
    } finally {
        const button = event.target;
        button.innerHTML = '<i class="fas fa-sync-alt"></i> Update Content';
        button.disabled = false;
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new PrepperPi();
});
