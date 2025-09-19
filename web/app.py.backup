#!/usr/bin/env python3
"""
PrepperPi Web Interface
Flask application for system management
"""

from flask import Flask, render_template, jsonify, request, redirect, url_for
import json
import subprocess
import os
import psutil
from datetime import datetime
from pathlib import Path

app = Flask(__name__)

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/api/system/stats')
def system_stats():
    """API endpoint for system statistics"""
    try:
        stats_file = Path('/opt/prepperpi/logs/system_stats.json')
        if stats_file.exists():
            with open(stats_file, 'r') as f:
                all_stats = json.load(f)
                return jsonify(all_stats[-1] if all_stats else {})
        
        # Return basic stats if file doesn't exist
        return jsonify({
            'cpu_percent': psutil.cpu_percent(),
            'memory': dict(psutil.virtual_memory()._asdict()),
            'disk': dict(psutil.disk_usage('/')._asdict()),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/content/update', methods=['POST'])
def update_content():
    """API endpoint to trigger content update"""
    try:
        # Run update script in background
        subprocess.Popen(['/opt/prepperpi/scripts/update_content.sh'])
        return jsonify({'status': 'Update started', 'success': True})
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/system/reboot', methods=['POST'])
def system_reboot():
    """API endpoint to reboot system"""
    try:
        subprocess.Popen(['sudo', 'reboot'])
        return jsonify({'status': 'Reboot initiated', 'success': True})
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/status')
def status():
    """System status page"""
    return render_template('status.html')

@app.route('/settings')
def settings():
    """Settings page"""
    return render_template('settings.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
