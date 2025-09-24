#!/usr/bin/env python3
"""
Tranquility Protocol — Instinct → Reason → Wisdom loop (TSL)
Minimal runnable Python skeleton with stubbed heuristics, rules, and logging.
Drop into your repo (e.g., balance_engine/tsl_loop.py) and run directly.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Tuple
import time
import json
import math
import random
from datetime import datetime

# --------------------------- Data Models ---------------------------
@dataclass
class Signal:
    kind: str
    source: str
    intensity: float  # 0..1
    timestamp: float
    raw: Dict[str, Any] = field(default_factory=dict)

@dataclass
class Context:
    actors: List[str]
    location: str
    history: List[Dict[str, Any]] = field(default_factory=list)
    norms: Dict[str, Any] = field(default_factory=dict)
    risk_level: str = "low"  # low | medium | high
    resources: Dict[str, Any] = field(default_factory=dict)

@dataclass
class Values:
    non_adversarial: bool = True
    proportionality: bool = True
    reversibility: bool = True
    transparency: str = "explain-brief"  # none | explain-brief | explain-full

@dataclass
class Policy:
    thresholds: Dict[str, float] = field(default_factory=lambda: {
        "alert": 0.35,
        "intervene": 0.55,
        "escalate": 0.80,
    })
    caps: Dict[str, Any] = field(default_factory=lambda: {
        "force": "minimal",           # minimal | moderate | strong
        "scope_max": "local",         # local | domain | global
        "duration_max": 60,            # seconds
    })
    cooldowns: Dict[str, float] = field(default_factory=lambda: {
        "after_intervene": 60.0,
        "after_escalate": 300.0,
    })
    escalation_paths: List[str] = field(default_factory=lambda: [
        "nudge", "request-clarity", "rate-limit", "pause-with-review"
    ])

@dataclass
class Assessment:
    instinct_score: float
    rule_score: float
    confidence: float

@dataclass
class Plan:
    action: str
    rationale: Dict[str, Any]

@dataclass
class Memory:
    incidents: List[Dict[str, Any]] = field(default_factory=list)
    models: Dict[str, Any] = field(default_factory=dict)
    reputation: Dict[str, Any] = field(default_factory=dict)

memory = Memory()

# --------------------------- Utilities ---------------------------

def now_ts() -> float:
    return time.time()


def sigmoid(x: float) -> float:
    return 1 / (1 + math.exp(-6*(x-0.5)))  # steeper around 0.5


def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


# --------------------------- Core Stages ---------------------------

def DETECT(inputs: List[Dict[str, Any]]) -> List[Signal]:
    """Normalize raw inputs into Signals (0..1 intensity, dedupe, tag)."""
    signals: List[Signal] = []
    seen: set[Tuple[str, str]] = set()
    for item in inputs:
        kind = item.get("kind", "unknown")
        source = item.get("source", "unknown")
        key = (kind, source)
        if key in seen:
            continue
        seen.add(key)
        raw_intensity = float(item.get("intensity", 0.0))
        # Simple normalization
        intensity = clamp(raw_intensity, 0.0, 1.0)
        signals.append(Signal(kind=kind, source=source, intensity=intensity,
                              timestamp=item.get("timestamp", now_ts()), raw=item))
    return signals


def fast_heuristics(signals: List[Signal], ctx: Context) -> float:
    """Instinct: quick read of spikes/anomalies; higher if many strong signals."""
    if not signals:
        return 0.0
    # Weight by intensity and scarcity of resources
    scarcity = 1.0 if not ctx.resources else clamp(1.0 - float(ctx.resources.get("buffer", 1.0)), 0.0, 1.0)
    avg = sum(s.intensity for s in signals) / len(signals)
    boost = 0.1 if ctx.risk_level == "medium" else (0.2 if ctx.risk_level == "high" else 0.0)
    return clamp(avg * (1 + scarcity) + boost, 0.0, 1.0)


def rules_engine(signals: List[Signal], ctx: Context, policy: Policy) -> float:
    """Reason: apply explicit norms/thresholds to produce a rule-based score."""
    score = 0.0
    for s in signals:
        # Example norms: certain kinds carry heavier concern
        if s.kind in ("harm-risk", "integrity-anomaly"):
            score += s.intensity * 0.6
        elif s.kind in ("noise",):
            score += s.intensity * 0.1
        else:
            score += s.intensity * 0.3
    # Normalize to 0..1 via tanh-ish squeeze
    return clamp(1 - math.exp(-score), 0.0, 1.0)


def estimate_confidence(signals: List[Signal], ctx: Context) -> float:
    n = len(signals)
    if n == 0:
        return 0.0
    # More diverse sources ⇒ higher confidence
    srcs = {s.source for s in signals}
    diversity = clamp(len(srcs)/5.0, 0.0, 1.0)
    # Recent history alignment boosts confidence
    hist_match = 0.0
    if ctx.history:
        recent = ctx.history[-min(5, len(ctx.history)):]
        hist_match = sum(1 for h in recent if h.get("kind") in {s.kind for s in signals})/max(1, len(recent))
    return clamp(0.4*diversity + 0.6*hist_match, 0.0, 1.0)


def EVALUATE(signals: List[Signal], ctx: Context, values: Values, policy: Policy) -> Assessment:
    instinct_score = fast_heuristics(signals, ctx)
    rule_score = rules_engine(signals, ctx, policy)
    confidence = estimate_confidence(signals, ctx)
    return Assessment(instinct_score=instinct_score, rule_score=rule_score, confidence=confidence)


def adapt_weight(channel: str, ctx: Context) -> float:
    """Wisdom: contextual weighting between instinct and reason."""
    if channel == "instinct":
        base = 0.5
        if ctx.risk_level == "high":
            base += 0.2
        if ctx.norms.get("prefer_speed", False):
            base += 0.1
        return clamp(base, 0.1, 0.9)
    if channel == "reason":
        base = 0.5
        if ctx.norms.get("prefer_rules", False):
            base += 0.2
        if ctx.risk_level == "low":
            base += 0.1
        return clamp(base, 0.1, 0.9)
    return 0.5


def propose_actions(blended: float, ctx: Context, policy: Policy) -> List[str]:
    t = policy.thresholds
    actions: List[str] = []
    if blended < t["alert"]:
        actions = ["observe"]
    elif blended < t["intervene"]:
        actions = ["nudge"]
    elif blended < t["escalate"]:
        actions = ["request-clarity", "rate-limit"]
    else:
        actions = ["pause-with-review", "rate-limit"]
    return actions


def filter_by_non_adversarial(actions: List[str], enabled: bool) -> List[str]:
    if not enabled:
        return actions
    # Drop heavy-handed actions unless truly necessary (kept only at escalate)
    soft = [a for a in actions if a in {"observe", "nudge", "request-clarity", "rate-limit"}]
    return soft if soft else actions


def enforce_proportionality(actions: List[str], caps: Dict[str, Any]) -> List[str]:
    if caps.get("force", "minimal") == "minimal":
        if "pause-with-review" in actions and "rate-limit" in actions:
            return ["rate-limit", "pause-with-review"]  # prefer lighter first
    return actions


def ensure_reversibility_first(actions: List[str]) -> List[str]:
    reversible = ["observe", "nudge", "request-clarity", "rate-limit"]
    # Stable sort: reversible first
    return sorted(actions, key=lambda a: a not in reversible)


def pick_min_sufficient(actions: List[str], ctx: Context) -> str:
    # Smallest effective: take the first (post-filters) as the plan
    return actions[0]


def ALIGN(assessment: Assessment, ctx: Context, values: Values, policy: Policy) -> Plan:
    w_instinct = clamp(adapt_weight("instinct", ctx), 0.0, 1.0)
    w_reason   = clamp(adapt_weight("reason", ctx), 0.0, 1.0)
    blended_in = w_instinct * assessment.instinct_score + w_reason * assessment.rule_score
    blended    = sigmoid(blended_in)

    action_set = propose_actions(blended, ctx, policy)
    action_set = filter_by_non_adversarial(action_set, values.non_adversarial)
    action_set = enforce_proportionality(action_set, policy.caps)
    action_set = ensure_reversibility_first(action_set)
    action = pick_min_sufficient(action_set, ctx)

    rationale = {
        "assessment": assessment.__dict__,
        "weights": {"instinct": w_instinct, "reason": w_reason},
        "blended": blended,
        "candidates": action_set,
    }
    return Plan(action=action, rationale=rationale)


def violates_caps(plan: Plan, policy: Policy) -> bool:
    if policy.caps.get("force") == "minimal" and plan.action == "pause-with-review":
        # Allow if blended was very high; otherwise suggest downgrade
        return plan.rationale.get("blended", 0.0) < 0.9
    return False


def downgrade(plan: Plan) -> Plan:
    # Try to step one notch lighter if available
    ladder = ["observe", "nudge", "request-clarity", "rate-limit", "pause-with-review"]
    try:
        idx = ladder.index(plan.action)
        if idx > 0:
            new_action = ladder[idx-1]
            plan.action = new_action
            plan.rationale["downgraded"] = True
    except ValueError:
        pass
    return plan


def execute(action: str) -> Dict[str, Any]:
    # Stub: emulate success probability and latency
    latency_ms = random.randint(20, 120)
    time.sleep(latency_ms / 1000.0)
    success_p = 0.95 if action in ("observe", "nudge") else 0.85
    ok = random.random() < success_p
    return {"ok": ok, "latency_ms": latency_ms}


def log_event(plan: Plan, outcome: Dict[str, Any]) -> None:
    entry = {
        "ts": datetime.utcnow().isoformat() + "Z",
        "action": plan.action,
        "rationale": plan.rationale,
        "outcome": outcome,
    }
    memory.incidents.append(entry)
    # Also print as a Transparency Grid note (brief)
    print(json.dumps({
        "TRANSPARENCY": {
            "ts": entry["ts"],
            "action": plan.action,
            "blended": round(plan.rationale.get("blended", 0.0), 3),
            "candidates": plan.rationale.get("candidates", []),
            "outcome": outcome,
        }
    }, ensure_ascii=False))


def update_models(models: Dict[str, Any], outcome: Dict[str, Any], plan: Plan, ctx: Context) -> None:
    # Simple running success rate per action
    stats = models.setdefault("action_stats", {})
    s = stats.setdefault(plan.action, {"tries": 0, "ok": 0})
    s["tries"] += 1
    s["ok"] += 1 if outcome.get("ok") else 0


def tune_weights_based_on_feedback(outcome: Dict[str, Any], plan: Plan) -> None:
    # Placeholder for RL-style adjustment; here we just note downgrades/latency
    return


def schedule_cooldown_if_needed(outcome: Dict[str, Any], plan: Plan) -> None:
    # Placeholder: could set timers or flags in memory
    return


def publish_transparency_note(plan: Plan, outcome: Dict[str, Any]) -> None:
    # Already printed in log_event; hook left for external sinks
    return


def ACT(plan: Plan) -> Dict[str, Any]:
    outcome = execute(plan.action)
    log_event(plan, outcome)
    return outcome


def LEARN(outcome: Dict[str, Any], plan: Plan, ctx: Context) -> None:
    update_models(memory.models, outcome, plan, ctx)
    tune_weights_based_on_feedback(outcome, plan)
    schedule_cooldown_if_needed(outcome, plan)
    publish_transparency_note(plan, outcome)


def TSL_CYCLE(inputs: List[Dict[str, Any]], ctx: Context, values: Values, policy: Policy) -> Dict[str, Any]:
    signals = DETECT(inputs)
    if not signals:
        return {"status": "idle"}

    assess = EVALUATE(signals, ctx, values, policy)
    plan = ALIGN(assess, ctx, values, policy)

    if violates_caps(plan, policy):
        plan = downgrade(plan)

    outcome = ACT(plan)
    LEARN(outcome, plan, ctx)
    return {"plan": plan.action, "outcome": outcome, "assessment": assess.__dict__}

# --------------------------- Demo Runner ---------------------------

def demo_once(seed: Optional[int] = None) -> None:
    if seed is not None:
        random.seed(seed)

    ctx = Context(
        actors=["user:mirko"],
        location="GroundNode:local",
        history=[{"kind": "integrity-anomaly"}, {"kind": "noise"}],
        norms={"prefer_rules": True},
        risk_level="medium",
        resources={"buffer": 0.6},
    )
    values = Values()
    policy = Policy()

    inputs = [
        {"kind": "integrity-anomaly", "source": "watcher", "intensity": 0.6},
        {"kind": "noise", "source": "logs", "intensity": 0.2},
        {"kind": "harm-risk", "source": "detector", "intensity": 0.4},
    ]

    result = TSL_CYCLE(inputs, ctx, values, policy)
    print("RESULT:", json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    # Run a single demo cycle
    demo_once(seed=42)
