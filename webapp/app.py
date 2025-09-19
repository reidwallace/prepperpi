from flask import Flask, render_template, jsonify
import subprocess, os

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/update/start", methods=["POST"])
def update_start():
    try:
        subprocess.check_call(["/bin/systemctl", "start", "prepperpi-update.service"])
        return jsonify({"ok": True, "msg": "Update started"})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500


@app.route("/update/log")
def update_log():
    p = "/var/log/prepperpi/update.log"
    if not os.path.exists(p):
        return jsonify({"ok": True, "log": ""})
    with open(p, "r") as f:
        return jsonify({"ok": True, "log": f.read()[-20000:]})


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5001)
