import hashlib
import json
import time
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

LEVEL_MAP = {
    "low": 0.2,
    "medium": 0.55,
    "high": 0.85,
}

INTERPRETATION_SIGNAL_WEIGHTS = {
    "offense-reactivity": 0.22,
    "certainty-spike": 0.20,
    "scarcity-spiral": 0.18,
    "adversarial-framing": 0.25,
    "fixation": 0.20,
    "rumination": 0.14,
}

PREACTION_BY_SIGNAL = {
    "offense-reactivity": "request-clarity",
    "certainty-spike": "seek-second-witness",
    "scarcity-spiral": "pause",
    "adversarial-framing": "restate-observation-without-judgment",
    "fixation": "boundary-without-escalation",
    "rumination": "pause",
}


def _clamp(value: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, value))


def _stable_unique(items):
    seen = set()
    result = []
    for item in items:
        if not item or item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


def _coerce_level(value, default: float) -> float:
    if isinstance(value, (int, float)):
        return _clamp(float(value))
    if isinstance(value, str):
        return _clamp(LEVEL_MAP.get(value.strip().lower(), default))
    return default


def _normalize_inner_signals(event: dict) -> list[str]:
    signals = []
    raw = event.get("inner_signals") or []
    if isinstance(raw, str):
        raw = [raw]
    if isinstance(raw, list):
        for item in raw:
            if isinstance(item, str):
                signals.append(item.strip().lower())
    return _stable_unique(signals)


def _estimate_evidence_strength(event: dict) -> float:
    explicit = event.get("evidence_strength")
    if isinstance(explicit, (int, float)):
        return _clamp(float(explicit))

    evidence = event.get("evidence") or []
    if not isinstance(evidence, list):
        evidence = []
    return _clamp(0.15 + 0.25 * len(evidence), 0.15, 0.9)


def _estimate_ambiguity_level(event: dict, evidence_strength: float) -> float:
    explicit = event.get("ambiguity_level")
    if explicit is not None:
        return _coerce_level(explicit, 0.4)
    return _clamp(0.75 - 0.5 * evidence_strength, 0.15, 0.85)


def _estimate_reversibility(event: dict) -> float:
    explicit = event.get("reversibility")
    if explicit is not None:
        return _coerce_level(explicit, 0.75)
    return 0.75


def _estimate_fatigue_load(event: dict) -> float:
    explicit = event.get("fatigue_load")
    if explicit is not None:
        return _coerce_level(explicit, 0.0)
    context = event.get("context") or {}
    return _coerce_level(context.get("fatigue_load"), 0.0)


def _active_harm_confirmed(event: dict, evidence_strength: float) -> bool:
    context = event.get("context") or {}
    if context.get("active_harm_confirmed") is True:
        return True
    etype = (event.get("type") or "").lower()
    return etype in {"kill", "destroy"} and evidence_strength >= 0.7


def _assess_interpretation(event: dict) -> dict:
    signals = _normalize_inner_signals(event)
    evidence_strength = _estimate_evidence_strength(event)
    ambiguity_level = _estimate_ambiguity_level(event, evidence_strength)
    reversibility = _estimate_reversibility(event)
    fatigue_load = _estimate_fatigue_load(event)
    active_harm = _active_harm_confirmed(event, evidence_strength)

    risk = 0.0
    notes = []

    for signal in signals:
        risk += INTERPRETATION_SIGNAL_WEIGHTS.get(signal, 0.0)

    risk += max(0.0, ambiguity_level - evidence_strength) * 0.45

    if evidence_strength < 0.45:
        risk += (0.45 - evidence_strength) * 0.5
        notes.append("evidence is still thin relative to the claim")

    if ambiguity_level > 0.6:
        notes.append("the situation is still materially ambiguous")

    if fatigue_load > 0.6:
        risk += (fatigue_load - 0.6) * 0.35
        notes.append("load is elevated and may distort interpretation")

    if reversibility < 0.4:
        risk += (0.4 - reversibility) * 0.2
        notes.append("the likely response is less reversible than usual")

    if "certainty-spike" in signals and evidence_strength < 0.6:
        notes.append("certainty appears to be outrunning available evidence")

    if "offense-reactivity" in signals and ambiguity_level > 0.5:
        notes.append("attribution may be forming before clarification")

    if "adversarial-framing" in signals:
        notes.append("framing is drifting toward opposition over diagnosis")

    risk = _clamp(risk)

    pre_action_checks = []
    if ambiguity_level >= 0.55 and not active_harm:
        pre_action_checks.append("request-clarity")
    if evidence_strength < 0.55 and not active_harm:
        pre_action_checks.append("seek-second-witness")
    if ambiguity_level >= 0.45:
        pre_action_checks.append("restate-observation-without-judgment")
    if reversibility < 0.5 and not active_harm:
        pre_action_checks.append("delay-irreversible-action")
    if fatigue_load >= 0.7 and not active_harm:
        pre_action_checks.append("pause")

    for signal in signals:
        mapped = PREACTION_BY_SIGNAL.get(signal)
        if mapped:
            pre_action_checks.append(mapped)

    if active_harm:
        pre_action_checks = [
            step for step in pre_action_checks
            if step not in {"request-clarity", "seek-second-witness", "delay-irreversible-action", "pause"}
        ]

    return {
        "reflective_signals": signals,
        "interpretation_risk": risk,
        "interpretation_notes": _stable_unique(notes),
        "pre_action_checks": _stable_unique(pre_action_checks),
        "evidence_strength": evidence_strength,
        "ambiguity_level": ambiguity_level,
        "reversibility": reversibility,
        "fatigue_load": fatigue_load,
        "active_harm_confirmed": active_harm,
    }


def _plan_for_opposite(opposite: str, event_type: str) -> tuple[list[str], float]:
    if opposite == "truth":
        return [
            "verify evidence from multiple sources",
            "publish correction with citations",
            "notify affected parties",
        ], 0.7
    if opposite == "stewardship":
        return [
            "seek consent from rights-holders",
            "negotiate fair-share or return/repair",
            "record trusteeship terms in writing",
        ], 0.7
    if opposite == "care":
        return [
            "halt harmful action",
            "protect vulnerable party",
            "initiate healing/repair protocol",
        ], 0.7
    if opposite == "creation":
        if event_type == "destroy":
            return [
                "stop destructive process",
                "design regenerative alternative",
                "implement maintain/improve cycle",
            ], 0.7
        return [
            "reinforce positive behavior",
            "document what worked",
            "share template for reuse",
        ], 0.9
    return ["reinforce positive behavior", "document what worked"], 0.9


def _ensure_files():
    for path in LEDGERS.values():
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_text("", encoding="utf-8")


def decide(event: dict) -> dict:
    """Pure function: map event to opposite + safe plan."""
    etype = (event.get("type") or "").lower()

    if etype in OPPOSITES:
        opposite = OPPOSITES[etype]
    elif etype in POSITIVE:
        opposite = etype
    else:
        opposite = "reinforce"

    plan, base_confidence = _plan_for_opposite(opposite, etype)
    interpretation = _assess_interpretation(event)

    if interpretation["pre_action_checks"] and not interpretation["active_harm_confirmed"]:
        plan = interpretation["pre_action_checks"] + plan

    confidence = _clamp(
        base_confidence
        + 0.10 * interpretation["evidence_strength"]
        - 0.20 * interpretation["interpretation_risk"],
        0.2,
        0.95,
    )

    next_steps = ["human-in-the-loop review if high impact", "create attestation"]
    if interpretation["pre_action_checks"]:
        next_steps.insert(0, "confirm pre-action checks before irreversible escalation")

    metrics_delta = {
        "expected_harm_reduced": 1 if etype in OPPOSITES else 0,
        "interpretation_drift_reduced": 1 if interpretation["interpretation_risk"] >= 0.45 else 0,
    }

    return {
        "event_id": event.get("id", ""),
        "opposite": opposite,
        "plan": _stable_unique(plan),
        "safety_checks": SAFETY_DEFAULTS.copy(),
        "confidence": confidence,
        "next_steps": _stable_unique(next_steps),
        "metrics_delta": metrics_delta,
        "interpretation_risk": interpretation["interpretation_risk"],
        "pre_action_checks": interpretation["pre_action_checks"],
        "reflective_signals": interpretation["reflective_signals"],
        "interpretation_notes": interpretation["interpretation_notes"],
        "evidence_strength": interpretation["evidence_strength"],
        "ambiguity_level": interpretation["ambiguity_level"],
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
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(line + "\n")
    return {"ok": True, "hash": digest, "ledger": str(path)}
