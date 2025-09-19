from flask import Flask, request, jsonify
from lib.engine import decide, attest

app = Flask(__name__)

@app.route("/decide", methods=["POST"])
def route_decide():
    event = request.get_json(force=True)
    decision = decide(event)
    return jsonify(decision)

@app.route("/attest", methods=["POST"])
def route_attest():
    payload = request.get_json(force=True)
    event = payload.get("event", {})
    decision = payload.get("decision", {})
    layer = payload.get("layer", event.get("layer_hint", "individual"))
    res = attest(event, decision, layer)
    return jsonify(res)

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True})

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5059, debug=True)
