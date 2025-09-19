import os, json, time, hashlib
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]

LEDGERS = {
    "individual": BASE / "ledgers" / "individual.jsonl",
    "system": BASE / "ledgers" / "system.jsonl",
    "planet": BASE / "ledgers" / "planet.jsonl",
}

OPPOSITES = {
    "lie": "truth",
    "steal": "stewardship",
    "kill": "care",
    "destroy": "creation",
}

POSITIVE = {"truth", "stewardship", "care", "creation"}

SAFETY_DEFAULTS = [
    "consent-first",
    "proportional-defense",
    "de-escalation",
    "transparency-hooks",
    "legal-compliance",
]

def _ensure_files():
    for p in LEDGERS.values():
        p.parent.mkdir(parents=True, exist_ok=True)
        if not p.exists():
            p.write_text("", encoding="utf-8")

def decide(event: dict) -> dict:
    """Pure function: map event to opposite + safe plan."""
    etype = (event.get("type") or "").lower()

    if etype in OPPOSITES:
        opposite = OPPOSITES[etype]
    elif etype in POSITIVE:
        opposite = etype  # show the positive, not "reinforce"
    else:
        opposite = "reinforce"

    safety = SAFETY_DEFAULTS.copy()

    # Lightweight plans
    if opposite == "truth":
        plan = ["verify evidence from multiple sources",
                "publish correction with citations",
                "notify affected parties"]
        conf = 0.7
    elif opposite == "stewardship":
        plan = ["seek consent from rights-holders",
                "negotiate fair-share or return/repair",
                "record trusteeship terms in writing"]
        conf = 0.7
    elif opposite == "care":
        plan = ["halt harmful action",
                "protect vulnerable party",
                "initiate healing/repair protocol"]
        conf = 0.7
    elif opposite == "creation":
        if etype == "destroy":
            plan = ["stop destructive process",
                    "design regenerative alternative",
                    "implement maintain/improve cycle"]
        else:
            plan = ["reinforce positive behavior",
                    "document what worked",
                    "share template for reuse"]
        conf = 0.7 if etype == "destroy" else 0.9
    else:
        plan = ["reinforce positive behavior", "document what worked"]
        conf = 0.9

    return {
        "event_id": event.get("id", ""),
        "opposite": opposite,
        "plan": plan,
        "safety_checks": safety,
        "confidence": conf,
        "next_steps": ["human-in-the-loop review if high impact", "create attestation"],
        "metrics_delta": {"expected_harm_reduced": 1 if etype in OPPOSITES else 0}
    }

def attest(event: dict, decision: dict, layer: str = "individual") -> dict:
    """Append an attestation line to the appropriate ledger."""
    _ensure_files()
    record = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "event": event,
        "decision": decision,
    }
    payload = json.dumps(record, ensure_ascii=False)
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    line = json.dumps({"hash": digest, "record": record}, ensure_ascii=False)
    path = LEDGERS.get(layer, LEDGERS["individual"])
    with path.open("a", encoding="utf-8", newline="\n") as f:
        f.write(line + "\n")
    return {"ok": True, "hash": digest, "ledger": str(path)}
