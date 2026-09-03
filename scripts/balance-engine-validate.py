#!/usr/bin/env python3
"""Validate the current local Balance Engine boundary and golden behavior."""

from __future__ import annotations

import json
import pathlib
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


try:
    from jsonschema import Draft202012Validator, FormatChecker
except ModuleNotFoundError:  # pragma: no cover - exercised on minimal local setups
    Draft202012Validator = None
    FormatChecker = None

from balance_engine.lib.engine import decide


EVENT_SCHEMA = ROOT / "balance_engine" / "schemas" / "event.schema.json"
DECISION_SCHEMA = ROOT / "balance_engine" / "schemas" / "decision.schema.json"
SAMPLE_EVENT = ROOT / "balance_engine" / "event.sample.json"


def load_json(path: pathlib.Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def fail(message: str) -> None:
    raise AssertionError(message)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def minimal_schema_check(instance: dict[str, Any], schema: dict[str, Any], label: str) -> None:
    for field in schema.get("required", []):
        require(field in instance, f"{label} missing required field: {field}")

    for field, rules in schema.get("properties", {}).items():
        if field not in instance:
            continue
        value = instance[field]
        expected = rules.get("type")
        if expected == "string":
            require(isinstance(value, str), f"{label}.{field} must be a string")
        elif expected == "number":
            require(isinstance(value, (int, float)), f"{label}.{field} must be a number")
            if "minimum" in rules:
                require(value >= rules["minimum"], f"{label}.{field} below minimum")
            if "maximum" in rules:
                require(value <= rules["maximum"], f"{label}.{field} above maximum")
        elif expected == "object":
            require(isinstance(value, dict), f"{label}.{field} must be an object")
        elif expected == "array":
            require(isinstance(value, list), f"{label}.{field} must be an array")

        enum = rules.get("enum")
        if enum:
            require(value in enum, f"{label}.{field} must be one of {enum}")


def validate(instance: dict[str, Any], schema_path: pathlib.Path, label: str) -> None:
    schema = load_json(schema_path)
    if Draft202012Validator is not None:
        Draft202012Validator.check_schema(schema)
        validator = Draft202012Validator(schema, format_checker=FormatChecker())
        errors = sorted(validator.iter_errors(instance), key=lambda error: list(error.absolute_path))
        if errors:
            lines = [f"{label} schema errors:"]
            for error in errors:
                where = ".".join(str(part) for part in error.absolute_path) or "$"
                lines.append(f"- {where}: {error.message}")
            fail("\n".join(lines))
    else:
        minimal_schema_check(instance, schema, label)


def event_fixture(**overrides: Any) -> dict[str, Any]:
    event: dict[str, Any] = {
        "id": "fixture-event",
        "type": "lie",
        "context": {},
        "timestamp": "2026-09-03T00:00:00Z",
        "evidence": [],
        "evidence_strength": 0.3,
        "ambiguity_level": "high",
        "reversibility": "medium",
        "inner_signals": [],
    }
    event.update(overrides)
    return event


def validate_decision(event: dict[str, Any]) -> dict[str, Any]:
    validate(event, EVENT_SCHEMA, "event")
    decision = decide(event)
    validate(decision, DECISION_SCHEMA, "decision")
    require(decision["event_id"] == event["id"], "decision event_id must match input event id")
    require(0 <= decision["confidence"] <= 1, "decision confidence must stay in range")
    return decision


def main() -> int:
    sample_event = load_json(SAMPLE_EVENT)
    sample_decision = validate_decision(sample_event)
    require("seek-second-witness" in sample_decision["pre_action_checks"], "sample must seek a second witness")
    require(
        "delay-irreversible-action" in sample_decision["pre_action_checks"],
        "sample must delay irreversible action",
    )

    thin_certainty = validate_decision(
        event_fixture(
            id="fixture-thin-certainty",
            type="lie",
            evidence_strength=0.2,
            ambiguity_level="high",
            inner_signals=["certainty-spike"],
        )
    )
    require("request-clarity" in thin_certainty["pre_action_checks"], "thin certainty must request clarity")
    require("seek-second-witness" in thin_certainty["pre_action_checks"], "thin certainty must seek witness")
    require(thin_certainty["interpretation_risk"] > 0, "thin certainty must expose interpretation risk")

    low_reversibility = validate_decision(
        event_fixture(
            id="fixture-low-reversibility",
            type="steal",
            evidence_strength=0.5,
            ambiguity_level="medium",
            reversibility="low",
        )
    )
    require(
        "delay-irreversible-action" in low_reversibility["pre_action_checks"],
        "low reversibility must delay irreversible action",
    )

    active_harm = validate_decision(
        event_fixture(
            id="fixture-active-harm",
            type="kill",
            evidence_strength=0.85,
            ambiguity_level="high",
            reversibility="low",
            fatigue_load=0.9,
            inner_signals=["certainty-spike", "adversarial-framing"],
        )
    )
    delay_only = {"request-clarity", "seek-second-witness", "delay-irreversible-action", "pause"}
    require(
        delay_only.isdisjoint(active_harm["pre_action_checks"]),
        "confirmed active harm must remove delay-only pre-action checks",
    )
    require(delay_only.isdisjoint(active_harm["plan"]), "confirmed active harm plan must not prepend delay-only checks")
    require(active_harm["opposite"] == "care", "kill event must map toward care")

    positive_truth = validate_decision(
        event_fixture(
            id="fixture-positive-truth",
            type="truth",
            evidence_strength=0.9,
            ambiguity_level="low",
            evidence=["public-source-a", "public-source-b"],
            inner_signals=[],
        )
    )
    require(positive_truth["opposite"] == "truth", "positive truth must map to truth")
    require(
        "publish correction with citations" not in positive_truth["plan"],
        "positive truth must not manufacture corrective publication",
    )
    require("reinforce positive behavior" in positive_truth["plan"], "positive truth should reinforce what worked")

    print("Balance Engine validation OK")
    if Draft202012Validator is None:
        print("jsonschema not installed; used minimal schema checks plus semantic golden fixtures")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Balance Engine validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
