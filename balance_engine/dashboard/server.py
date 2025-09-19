from pathlib import Path
from flask import Flask, jsonify, send_from_directory
import json, os

ROOT = Path(__file__).resolve().parents[1]
LEDGER_DIR = ROOT / "ledgers"

app = Flask(__name__, static_folder="static", static_url_path="/static")

def read_jsonl(path, limit=50):
    if not path.exists(): return []
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.read().splitlines()
    except Exception:
        return []
    items = []
    for line in lines[-limit:]:
        try:
            items.append(json.loads(line))
        except Exception:
            continue
    return items[::-1]  # newest first

@app.get("/api/recent")
def api_recent():
    data = {
        "individual": read_jsonl(LEDGER_DIR / "individual.jsonl", 50),
        "system":     read_jsonl(LEDGER_DIR / "system.jsonl", 50),
        "planet":     read_jsonl(LEDGER_DIR / "planet.jsonl", 50),
    }
    return jsonify(data)

@app.get("/")
def index():
    return send_from_directory("static", "index.html")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8059"))
    app.run(host="127.0.0.1", port=port, debug=True)
