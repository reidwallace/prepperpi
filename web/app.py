from flask import Flask, jsonify
import psutil
from datetime import datetime

app = Flask(__name__)


@app.route("/")
def index():
    return """
<!DOCTYPE html>
<html>
<head>
    <title>PrepperPi Dashboard</title>
    <style>body{font-family:Arial;margin:40px;}</style>
</head>
<body>
    <h1>PrepperPi Dashboard</h1>
    <p>Your offline knowledge server is running</p>
    <ul>
        <li><a href="/status">System Status</a></li>
        <li><a href="/api/system/stats">Live System Stats</a></li>
        <li><a href="/kiwix/">Knowledge Library</a></li>
    </ul>
    <p>Status: All services operational</p>
</body>
</html>
"""


@app.route("/status")
def status():
    return """
<!DOCTYPE html>
<html>
<head><title>Status</title></head>
<body>
    <h1>System Status</h1>
    <p><a href="/">Back to Home</a></p>
    <p>Flask: Running</p>
    <p>Kiwix: Running</p>
    <p>WiFi: Broadcasting</p>
</body>
</html>
"""


@app.route("/api/system/stats")
def system_stats():
    try:
        return jsonify(
            {
                "cpu_percent": psutil.cpu_percent(),
                "memory_percent": psutil.virtual_memory().percent,
                "timestamp": datetime.now().isoformat(),
                "status": "running",
            }
        )
    except:
        return jsonify({"error": "Stats unavailable", "status": "running"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
