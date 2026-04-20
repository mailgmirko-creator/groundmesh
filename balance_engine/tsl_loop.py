#!/usr/bin/env python3
"""
Tranquility Protocol - Instinct -> Reason -> Wisdom loop (TSL)
Minimal runnable Python skeleton with interpretation hygiene, rules, and logging.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
import json
import math
import random
import time
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class Signal:
    kind: str
    source: str
    intensity: float
    timestamp: float
    raw: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Context:
    actors: List[str]
    location: str
    history: List[Dict[str, Any]] = field(default_factory=list)
    norms: Dict[str, Any] = field(default_factory=dict)
    risk_level: str = "low"
    resources: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Values:
    non_adversarial: bool = True
    proportionality: bool = True
    reversibility: bool = True
    transparency: str = "explain-brief"


@dataclass
class Policy:
    thresholds: Dict[str, float] = field(default_factory=lambda: {
        "alert": 0.35,
        "intervene": 0.55,
        "escalate": 0.80,
    })
    caps: Dict[str, Any] = field(default_factory=lambda: {
        "force": "minimal",
        "scope_max": "local",
        "duration_max": 60,
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
    evidence_strength: float = 0.0
    ambiguity_level: float = 0.0
    interpretation_risk: float = 0.0
    interpretation_notes: List[str] = field(default_factory=list)


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

LEVEL_MAP = {
    "low": 0.2,
    "medium": 0.55,
    "high": 0.85,
}

INNER_SIGNAL_WEIGHTS = {
    "offense-reactivity": 0.22,
    "certainty-spike": 0.20,
    "scarcity-spiral": 0.18,
    "adversarial-framing": 0.25,
    "fixation": 0.20,
    "rumination": 0.14,
}

INNER_SIGNAL_ACTIONS = {
    "offense-reactivity": "request-clarity",
    "certainty-spike": "seek-second-witness",
    "scarcity-spiral": "pause",
    "adversarial-framing": "restate-observation-without-judgment",
    "fixation": "boundary-without-escalation",
    "rumination": "pause",
}


def now_ts() -> float:
    return time.time()


def sigmoid(x: float) -> float:
    return 1 / (1 + math.exp(-6 * (x - 0.5)))


def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


def stable_unique(items: List[str]) -> List[str]:
    seen = set()
    result: List[str] = []
    for item in items:
        if not item or item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


def coerce_level(value: Any, default: float) -> float:
    if isinstance(value, (int, float)):
        return clamp(float(value), 0.0, 1.0)
    if isinstance(value, str):
        return clamp(LEVEL_MAP.get(value.strip().lower(), default), 0.0, 1.0)
    return default


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
        intensity = clamp(raw_intensity, 0.0, 1.0)
        signals.append(
            Signal(
                kind=kind,
                source=source,
                intensity=intensity,
                timestamp=item.get("timestamp", now_ts()),
                raw=item,
            )
        )
    return signals


def fast_heuristics(signals: List[Signal], ctx: Context) -> float:
    """Instinct: quick read of spikes/anomalies; higher if many strong signals."""
    if not signals:
        return 0.0
    scarcity = 1.0 if not ctx.resources else clamp(1.0 - float(ctx.resources.get("buffer", 1.0)), 0.0, 1.0)
    avg = sum(signal.intensity for signal in signals) / len(signals)
    boost = 0.1 if ctx.risk_level == "medium" else (0.2 if ctx.risk_level == "high" else 0.0)
    return clamp(avg * (1 + scarcity) + boost, 0.0, 1.0)


def rules_engine(signals: List[Signal], ctx: Context, policy: Policy) -> float:
    """Reason: apply explicit norms/thresholds to produce a rule-based score."""
    score = 0.0
    for signal in signals:
        if signal.kind in ("harm-risk", "integrity-anomaly"):
            score += signal.intensity * 0.6
        elif signal.kind in ("noise",):
            score += signal.intensity * 0.1
        else:
            score += signal.intensity * 0.3
    return clamp(1 - math.exp(-score), 0.0, 1.0)


def normalized_inner_signals(signals: List[Signal]) -> List[str]:
    names: List[str] = []
    for signal in signals:
        if signal.kind in INNER_SIGNAL_WEIGHTS:
            names.append(signal.kind)
        raw_inner = signal.raw.get("inner_signals") or []
        if isinstance(raw_inner, str):
            raw_inner = [raw_inner]
        if isinstance(raw_inner, list):
            for item in raw_inner:
                if isinstance(item, str):
                    names.append(item.strip().lower())
    return stable_unique(names)


def estimate_evidence_strength(signals: List[Signal], ctx: Context) -> float:
    explicit_values: List[float] = []
    evidence_counts: List[float] = []

    for signal in signals:
        raw = signal.raw or {}
        explicit = raw.get("evidence_strength")
        if isinstance(explicit, (int, float)):
            explicit_values.append(clamp(float(explicit), 0.0, 1.0))

        evidence = raw.get("evidence") or []
        if isinstance(evidence, list):
            evidence_counts.append(clamp(0.15 + 0.25 * len(evidence), 0.15, 0.9))

    if explicit_values:
        return sum(explicit_values) / len(explicit_values)
    if evidence_counts:
        return sum(evidence_counts) / len(evidence_counts)

    if ctx.resources:
        buffer = ctx.resources.get("buffer")
        if isinstance(buffer, (int, float)):
            return clamp(0.35 + 0.4 * float(buffer), 0.0, 1.0)

    return 0.5


def estimate_ambiguity_level(signals: List[Signal], ctx: Context, evidence_strength: float) -> float:
    explicit_values: List[float] = []
    for signal in signals:
        raw = signal.raw or {}
        value = raw.get("ambiguity_level")
        if value is not None:
            explicit_values.append(coerce_level(value, 0.4))

    if explicit_values:
        return sum(explicit_values) / len(explicit_values)

    if ctx.norms.get("ambiguity_level") is not None:
        return coerce_level(ctx.norms.get("ambiguity_level"), 0.4)

    return clamp(0.75 - 0.5 * evidence_strength, 0.15, 0.85)


def active_harm_confirmed(signals: List[Signal], ctx: Context, evidence_strength: float) -> bool:
    if ctx.norms.get("active_harm_confirmed") is True:
        return True
    for signal in signals:
        raw = signal.raw or {}
        if raw.get("active_harm_confirmed") is True:
            return True
        if signal.kind == "harm-risk" and signal.intensity >= 0.8 and evidence_strength >= 0.55:
            return True
    return False


def assess_interpretation(
    signals: List[Signal],
    ctx: Context,
    evidence_strength: float,
    ambiguity_level: float,
) -> Tuple[float, List[str]]:
    risk = 0.0
    notes: List[str] = []
    inner_signals = normalized_inner_signals(signals)

    for name in inner_signals:
        risk += INNER_SIGNAL_WEIGHTS.get(name, 0.0)

    risk += max(0.0, ambiguity_level - evidence_strength) * 0.45

    if evidence_strength < 0.45:
        risk += (0.45 - evidence_strength) * 0.5
        notes.append("evidence is still thin relative to the claim")

    if ambiguity_level > 0.6:
        notes.append("the situation is still materially ambiguous")

    if ctx.resources:
        buffer = ctx.resources.get("buffer")
        if isinstance(buffer, (int, float)) and float(buffer) < 0.3:
            risk += (0.3 - float(buffer)) * 0.35
            notes.append("resource buffer is low and may amplify reactivity")

    if "certainty-spike" in inner_signals and evidence_strength < 0.6:
        notes.append("certainty appears to be outrunning available evidence")

    if "offense-reactivity" in inner_signals and ambiguity_level > 0.5:
        notes.append("attribution may be forming before clarification")

    if "adversarial-framing" in inner_signals:
        notes.append("framing is drifting toward opposition over diagnosis")

    return clamp(risk, 0.0, 1.0), stable_unique(notes)


def estimate_confidence(
    signals: List[Signal],
    ctx: Context,
    evidence_strength: float,
    interpretation_risk: float,
) -> float:
    if not signals:
        return 0.0
    srcs = {signal.source for signal in signals}
    diversity = clamp(len(srcs) / 5.0, 0.0, 1.0)
    hist_match = 0.0
    if ctx.history:
        recent = ctx.history[-min(5, len(ctx.history)):]
        hist_match = sum(1 for item in recent if item.get("kind") in {signal.kind for signal in signals}) / max(1, len(recent))
    return clamp(
        0.35 * diversity
        + 0.35 * hist_match
        + 0.30 * evidence_strength
        - 0.20 * interpretation_risk,
        0.0,
        1.0,
    )


def EVALUATE(signals: List[Signal], ctx: Context, values: Values, policy: Policy) -> Assessment:
    instinct_score = fast_heuristics(signals, ctx)
    rule_score = rules_engine(signals, ctx, policy)
    evidence_strength = estimate_evidence_strength(signals, ctx)
    ambiguity_level = estimate_ambiguity_level(signals, ctx, evidence_strength)
    interpretation_risk, interpretation_notes = assess_interpretation(
        signals, ctx, evidence_strength, ambiguity_level
    )
    confidence = estimate_confidence(signals, ctx, evidence_strength, interpretation_risk)
    return Assessment(
        instinct_score=instinct_score,
        rule_score=rule_score,
        confidence=confidence,
        evidence_strength=evidence_strength,
        ambiguity_level=ambiguity_level,
        interpretation_risk=interpretation_risk,
        interpretation_notes=interpretation_notes,
    )


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
    thresholds = policy.thresholds
    if blended < thresholds["alert"]:
        return ["observe"]
    if blended < thresholds["intervene"]:
        return ["nudge"]
    if blended < thresholds["escalate"]:
        return ["request-clarity", "rate-limit"]
    return ["pause-with-review", "rate-limit"]


def derive_pre_action_checks(assessment: Assessment, signals: List[Signal], ctx: Context) -> List[str]:
    checks: List[str] = []
    active_harm = active_harm_confirmed(signals, ctx, assessment.evidence_strength)
    inner_signals = normalized_inner_signals(signals)

    if assessment.ambiguity_level >= 0.55 and not active_harm:
        checks.append("request-clarity")
    if assessment.evidence_strength < 0.55 and not active_harm:
        checks.append("seek-second-witness")
    if assessment.ambiguity_level >= 0.45:
        checks.append("restate-observation-without-judgment")
    if assessment.interpretation_risk >= 0.65 and not active_harm:
        checks.append("delay-irreversible-action")

    if ctx.resources:
        buffer = ctx.resources.get("buffer")
        if isinstance(buffer, (int, float)) and float(buffer) < 0.25 and not active_harm:
            checks.append("pause")

    for name in inner_signals:
        mapped = INNER_SIGNAL_ACTIONS.get(name)
        if mapped:
            checks.append(mapped)

    if active_harm:
        checks = [
            step for step in checks
            if step not in {"request-clarity", "seek-second-witness", "delay-irreversible-action", "pause"}
        ]

    return stable_unique(checks)


def filter_by_non_adversarial(actions: List[str], enabled: bool) -> List[str]:
    if not enabled:
        return actions
    soft = [
        action for action in actions
        if action in {
            "observe",
            "nudge",
            "restate-observation-without-judgment",
            "request-clarity",
            "seek-second-witness",
            "boundary-without-escalation",
            "delay-irreversible-action",
            "rate-limit",
            "pause",
        }
    ]
    return soft if soft else actions


def enforce_proportionality(actions: List[str], caps: Dict[str, Any]) -> List[str]:
    if caps.get("force", "minimal") == "minimal":
        if "pause-with-review" in actions and "rate-limit" in actions:
            return ["rate-limit", "pause-with-review"]
    return actions


def ensure_reversibility_first(actions: List[str]) -> List[str]:
    reversible = {
        "observe",
        "nudge",
        "restate-observation-without-judgment",
        "request-clarity",
        "seek-second-witness",
        "boundary-without-escalation",
        "delay-irreversible-action",
        "rate-limit",
        "pause",
    }
    return sorted(actions, key=lambda action: action not in reversible)


def pick_min_sufficient(actions: List[str], ctx: Context) -> str:
    return actions[0]


def ALIGN(assessment: Assessment, signals: List[Signal], ctx: Context, values: Values, policy: Policy) -> Plan:
    w_instinct = clamp(adapt_weight("instinct", ctx), 0.0, 1.0)
    w_reason = clamp(adapt_weight("reason", ctx), 0.0, 1.0)
    blended_in = w_instinct * assessment.instinct_score + w_reason * assessment.rule_score
    blended = sigmoid(blended_in)

    action_set = propose_actions(blended, ctx, policy)
    pre_action_checks = derive_pre_action_checks(assessment, signals, ctx)
    if pre_action_checks:
        action_set = pre_action_checks + action_set
    action_set = stable_unique(action_set)
    action_set = filter_by_non_adversarial(action_set, values.non_adversarial)
    action_set = enforce_proportionality(action_set, policy.caps)
    action_set = ensure_reversibility_first(action_set)
    action = pick_min_sufficient(action_set, ctx)

    rationale = {
        "assessment": assessment.__dict__,
        "weights": {"instinct": w_instinct, "reason": w_reason},
        "blended": blended,
        "candidates": action_set,
        "pre_action_checks": pre_action_checks,
        "interpretation_notes": assessment.interpretation_notes,
    }
    return Plan(action=action, rationale=rationale)


def violates_caps(plan: Plan, policy: Policy) -> bool:
    if policy.caps.get("force") == "minimal" and plan.action == "pause-with-review":
        return plan.rationale.get("blended", 0.0) < 0.9
    return False


def downgrade(plan: Plan) -> Plan:
    ladder = [
        "observe",
        "nudge",
        "restate-observation-without-judgment",
        "request-clarity",
        "seek-second-witness",
        "boundary-without-escalation",
        "delay-irreversible-action",
        "rate-limit",
        "pause",
        "pause-with-review",
    ]
    try:
        idx = ladder.index(plan.action)
        if idx > 0:
            plan.action = ladder[idx - 1]
            plan.rationale["downgraded"] = True
    except ValueError:
        pass
    return plan


def execute(action: str) -> Dict[str, Any]:
    latency_ms = random.randint(20, 120)
    time.sleep(latency_ms / 1000.0)
    success_p = 0.95 if action in (
        "observe",
        "nudge",
        "restate-observation-without-judgment",
        "request-clarity",
        "seek-second-witness",
        "boundary-without-escalation",
        "delay-irreversible-action",
        "pause",
    ) else 0.85
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
    print(json.dumps({
        "TRANSPARENCY": {
            "ts": entry["ts"],
            "action": plan.action,
            "blended": round(plan.rationale.get("blended", 0.0), 3),
            "candidates": plan.rationale.get("candidates", []),
            "pre_action_checks": plan.rationale.get("pre_action_checks", []),
            "outcome": outcome,
        }
    }, ensure_ascii=False))


def update_models(models: Dict[str, Any], outcome: Dict[str, Any], plan: Plan, ctx: Context) -> None:
    stats = models.setdefault("action_stats", {})
    action_stats = stats.setdefault(plan.action, {"tries": 0, "ok": 0})
    action_stats["tries"] += 1
    action_stats["ok"] += 1 if outcome.get("ok") else 0


def tune_weights_based_on_feedback(outcome: Dict[str, Any], plan: Plan) -> None:
    return


def schedule_cooldown_if_needed(outcome: Dict[str, Any], plan: Plan) -> None:
    return


def publish_transparency_note(plan: Plan, outcome: Dict[str, Any]) -> None:
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
    plan = ALIGN(assess, signals, ctx, values, policy)

    if violates_caps(plan, policy):
        plan = downgrade(plan)

    outcome = ACT(plan)
    LEARN(outcome, plan, ctx)
    return {"plan": plan.action, "outcome": outcome, "assessment": assess.__dict__}


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
        {
            "kind": "integrity-anomaly",
            "source": "watcher",
            "intensity": 0.6,
            "inner_signals": ["certainty-spike"],
            "evidence_strength": 0.35,
            "ambiguity_level": "high",
        },
        {"kind": "noise", "source": "logs", "intensity": 0.2},
        {
            "kind": "harm-risk",
            "source": "detector",
            "intensity": 0.4,
            "inner_signals": ["offense-reactivity"],
        },
    ]

    result = TSL_CYCLE(inputs, ctx, values, policy)
    print("RESULT:", json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    demo_once(seed=42)
