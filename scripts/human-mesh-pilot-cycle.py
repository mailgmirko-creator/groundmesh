#!/usr/bin/env python3
"""GroundMesh Human Mesh H1 local pilot lifecycle bridge.

This intentionally has no publish command. It reads an existing local invited-circle
registration submission, creates only a participant-approved public candidate draft,
and keeps candidates / decisions / event drafts inside the gitignored local pilot
workspace.

Run `python scripts/human-mesh-pilot-cycle.py dry-run` for the synthetic CI cycle.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import pathlib
import re
import sys
import tempfile
import uuid
from copy import deepcopy
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_WORKSPACE = ROOT / "private" / "registration_pilot" / "human_mesh"
DECLARATION_SCHEMA = ROOT / "docs" / "human-mesh" / "schema" / "v0.1.schema.json"
EVENT_SCHEMA = ROOT / "docs" / "human-mesh" / "schema" / "accountability-event.v0.1.schema.json"
VALIDATOR_PATH = ROOT / "scripts" / "human-mesh-validate.py"

DECISIONS = {"approve", "pause", "reject"}
COMMITMENTS = [
    "welcome_corrections",
    "disclose_relevant_conflicts",
    "keep_stewardship_actions_inspectable",
    "publish_material_corrections",
    "respect_voluntary_participation",
    "avoid_person_scoring",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_json(path: pathlib.Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: pathlib.Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def append_jsonl(path: pathlib.Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(value, ensure_ascii=False) + "\n")


def load_validator_module():
    spec = importlib.util.spec_from_file_location("groundmesh_human_mesh_validate", VALIDATOR_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load validator module: {VALIDATOR_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


HM = load_validator_module()
DECLARATION_VALIDATOR = HM.load_schema(DECLARATION_SCHEMA)
EVENT_VALIDATOR = HM.load_schema(EVENT_SCHEMA)


def assert_valid_declaration(record: dict) -> None:
    errors = HM.validate_record(record, DECLARATION_VALIDATOR, HM.validate_declaration_semantics)
    if errors:
        raise ValueError("invalid Human Mesh declaration:\n- " + "\n- ".join(errors))


def assert_valid_event(record: dict) -> None:
    errors = HM.validate_record(record, EVENT_VALIDATOR, HM.validate_event_semantics)
    if errors:
        raise ValueError("invalid Human Mesh accountability event:\n- " + "\n- ".join(errors))


def workspace_paths(workspace: pathlib.Path) -> dict[str, pathlib.Path]:
    return {
        "candidates": workspace / "candidates",
        "decisions": workspace / "decisions",
        "events": workspace / "events",
        "index": workspace / "index.json",
    }


def load_index(workspace: pathlib.Path) -> dict:
    path = workspace_paths(workspace)["index"]
    if not path.is_file():
        return {"by_node_id": {}, "by_source_record_id": {}}
    data = load_json(path)
    data.setdefault("by_node_id", {})
    data.setdefault("by_source_record_id", {})
    return data


def save_index(workspace: pathlib.Path, index: dict) -> None:
    write_json(workspace_paths(workspace)["index"], index)


def candidate_files(workspace: pathlib.Path, node_id: str) -> list[pathlib.Path]:
    root = workspace_paths(workspace)["candidates"]
    return sorted(root.glob(f"{node_id}.v*.json"), key=lambda p: int(re.search(r"\.v(\d+)\.json$", p.name).group(1)))


def latest_candidate(workspace: pathlib.Path, node_id: str) -> tuple[pathlib.Path, dict]:
    files = candidate_files(workspace, node_id)
    if not files:
        raise ValueError(f"no candidate found for {node_id}")
    path = files[-1]
    return path, load_json(path)


def next_version(workspace: pathlib.Path, node_id: str) -> int:
    files = candidate_files(workspace, node_id)
    return 1 if not files else int(re.search(r"\.v(\d+)\.json$", files[-1].name).group(1)) + 1


def safe_public_display_name(value: str) -> str:
    value = value.strip()
    if not value:
        raise ValueError("public display name is required")
    if "@" in value or re.fullmatch(r"[+()\-\d\s]{7,}", value):
        raise ValueError("public display name looks like private contact data; choose a public name or stable pseudonym")
    return value[:80]


def make_node_id(requested: str) -> str:
    if requested == "auto":
        return f"human-{uuid.uuid4().hex[:12]}"
    return requested


def require_participant_consent(value: bool) -> None:
    if value is not True:
        raise ValueError("explicit participant consent is required; candidate creation is not inferred from the older pilot form")


def prepare_candidate(
    submission_path: pathlib.Path,
    workspace: pathlib.Path,
    node_id: str,
    identity_mode: str,
    location_precision: str,
    location_label: str,
    country_code: str | None,
    display_name: str | None,
    public_statement: str | None,
    affirmed_at: str,
    participant_consent: bool,
) -> pathlib.Path:
    require_participant_consent(participant_consent)
    submission = load_json(submission_path)
    source_record_id = str(submission.get("record_id", "")).strip()
    if not source_record_id:
        raise ValueError("pilot submission must contain record_id")
    if submission.get("consent_ordinary_email_only") is not True:
        raise ValueError("pilot submission did not acknowledge the ordinary-channel limitation")

    index = load_index(workspace)
    if source_record_id in index["by_source_record_id"]:
        raise ValueError(f"duplicate pilot source record: {source_record_id}")

    node_id = make_node_id(node_id)
    if node_id in index["by_node_id"]:
        raise ValueError(f"duplicate Human Mesh node id: {node_id}")

    chosen_name = safe_public_display_name(display_name or str(submission.get("display_name", "")))
    created_at = utc_now()
    location = {"precision": location_precision, "label": location_label.strip()[:120]}
    if country_code:
        location["country_code"] = country_code.upper()

    candidate = {
        "schema_version": "0.1",
        "node_id": node_id,
        "node_type": "human",
        "public_identity": {
            "display_name": chosen_name,
            "identity_mode": identity_mode,
            "continuity_acknowledged": True,
        },
        "location": location,
        "accountability_commitments": COMMITMENTS,
        "consent": {
            "public_fields": True,
            "location_precision": True,
            "provenance_history": True,
            "rules_version": "human-mesh-foundation-v0.1",
            "right_to_correct_withdraw": True,
            "affirmed_at": affirmed_at,
        },
        "lifecycle": {"status": "candidate", "effective_at": created_at},
        "provenance": {
            "record_version": 1,
            "created_at": created_at,
            "created_by": "GroundMesh H1 local pilot bridge",
            "supersedes_record_version": None,
        },
    }
    if public_statement:
        candidate["public_statement"] = public_statement.strip()[:1000]

    assert_valid_declaration(candidate)

    candidate_path = workspace_paths(workspace)["candidates"] / f"{node_id}.v1.json"
    write_json(candidate_path, candidate)
    index["by_node_id"][node_id] = {"source_record_id": source_record_id, "latest_version": 1}
    index["by_source_record_id"][source_record_id] = node_id
    save_index(workspace, index)
    append_jsonl(
        workspace_paths(workspace)["decisions"] / f"{node_id}.jsonl",
        {
            "at": created_at,
            "type": "candidate_prepared",
            "node_id": node_id,
            "record_version": 1,
            "source_record_id": source_record_id,
            "publication": "not_authorized",
        },
    )
    return candidate_path


def record_decision(workspace: pathlib.Path, node_id: str, decision: str, steward: str, reason: str) -> dict:
    if decision not in DECISIONS:
        raise ValueError(f"decision must be one of: {', '.join(sorted(DECISIONS))}")
    _, candidate = latest_candidate(workspace, node_id)
    event = {
        "at": utc_now(),
        "type": "steward_decision",
        "node_id": node_id,
        "record_version": candidate["provenance"]["record_version"],
        "decision": decision,
        "steward": steward.strip()[:100] or "local-steward",
        "reason": reason.strip()[:1000],
        "publication": "not_authorized",
    }
    append_jsonl(workspace_paths(workspace)["decisions"] / f"{node_id}.jsonl", event)
    return event


def correct_candidate(
    workspace: pathlib.Path,
    node_id: str,
    display_name: str | None,
    location_label: str | None,
    public_statement: str | None,
    affirmed_at: str,
    participant_affirmed: bool,
) -> pathlib.Path:
    require_participant_consent(participant_affirmed)
    _, current = latest_candidate(workspace, node_id)
    if current["lifecycle"]["status"] == "withdrawn":
        raise ValueError("withdrawn candidate cannot be corrected; restoration would be a separate participant action")

    updated = deepcopy(current)
    changed = False
    if display_name is not None:
        updated["public_identity"]["display_name"] = safe_public_display_name(display_name)
        changed = True
    if location_label is not None:
        updated["location"]["label"] = location_label.strip()[:120]
        changed = True
    if public_statement is not None:
        if public_statement:
            updated["public_statement"] = public_statement.strip()[:1000]
        else:
            updated.pop("public_statement", None)
        changed = True
    if not changed:
        raise ValueError("correction requires at least one changed public field")

    old_version = int(current["provenance"]["record_version"])
    new_version = next_version(workspace, node_id)
    now = utc_now()
    updated["consent"]["affirmed_at"] = affirmed_at
    updated["lifecycle"] = {"status": "candidate", "effective_at": now}
    updated["provenance"] = {
        "record_version": new_version,
        "created_at": now,
        "created_by": "GroundMesh H1 participant correction bridge",
        "supersedes_record_version": old_version,
    }
    assert_valid_declaration(updated)

    path = workspace_paths(workspace)["candidates"] / f"{node_id}.v{new_version}.json"
    write_json(path, updated)
    index = load_index(workspace)
    index["by_node_id"][node_id]["latest_version"] = new_version
    save_index(workspace, index)
    append_jsonl(
        workspace_paths(workspace)["decisions"] / f"{node_id}.jsonl",
        {
            "at": now,
            "type": "participant_correction",
            "node_id": node_id,
            "record_version": new_version,
            "supersedes_record_version": old_version,
            "publication": "not_authorized",
        },
    )
    # A changed candidate always requires fresh steward review.
    record_decision(workspace, node_id, "pause", "system", "participant correction requires fresh steward review")
    return path


def withdraw_candidate(
    workspace: pathlib.Path,
    node_id: str,
    statement: str,
    affirmed_at: str,
    participant_affirmed: bool,
) -> tuple[pathlib.Path, pathlib.Path]:
    require_participant_consent(participant_affirmed)
    _, current = latest_candidate(workspace, node_id)
    old_version = int(current["provenance"]["record_version"])
    new_version = next_version(workspace, node_id)
    now = utc_now()

    withdrawn = deepcopy(current)
    withdrawn["consent"]["affirmed_at"] = affirmed_at
    withdrawn["lifecycle"] = {"status": "withdrawn", "effective_at": now}
    withdrawn["provenance"] = {
        "record_version": new_version,
        "created_at": now,
        "created_by": "GroundMesh H1 participant withdrawal bridge",
        "supersedes_record_version": old_version,
    }
    assert_valid_declaration(withdrawn)

    declaration_path = workspace_paths(workspace)["candidates"] / f"{node_id}.v{new_version}.json"
    write_json(declaration_path, withdrawn)

    event = {
        "schema_version": "0.1",
        "event_id": f"hm-event-{uuid.uuid4().hex[:16]}",
        "node_id": node_id,
        "event_type": "withdrawal",
        "statement": statement.strip()[:2000],
        "authorship": {"self_authored": True, "actor_node_id": node_id},
        "visibility": "public_by_consent",
        "created_at": affirmed_at,
        "supersedes_event_id": None,
    }
    assert_valid_event(event)
    event_path = workspace_paths(workspace)["events"] / f"{event['event_id']}.draft.json"
    write_json(event_path, event)

    index = load_index(workspace)
    index["by_node_id"][node_id]["latest_version"] = new_version
    save_index(workspace, index)
    append_jsonl(
        workspace_paths(workspace)["decisions"] / f"{node_id}.jsonl",
        {
            "at": now,
            "type": "participant_withdrawal",
            "node_id": node_id,
            "record_version": new_version,
            "publication": "not_authorized",
            "event_draft": event_path.name,
        },
    )
    return declaration_path, event_path


def decision_history(workspace: pathlib.Path, node_id: str) -> list[dict]:
    path = workspace_paths(workspace)["decisions"] / f"{node_id}.jsonl"
    if not path.is_file():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def run_dry_run() -> None:
    with tempfile.TemporaryDirectory(prefix="groundmesh-human-mesh-h1-") as raw:
        temp = pathlib.Path(raw)
        workspace = temp / "private" / "registration_pilot" / "human_mesh"
        submission_path = temp / "participant-0001-space-monkey.json"
        submission = {
            "display_name": "Space Monkey One",
            "region_or_country": "Exampleland",
            "participation_type": "Public declaration",
            "reply_contact": "private-contact@example.invalid",
            "contact_preference": "Email",
            "privacy_request": "Public declaration",
            "note": "Synthetic H1 fixture only.",
            "consent_ordinary_email_only": True,
            "record_id": "participant-0001",
            "received_at": "2026-08-25T20:00:00+00:00",
            "steward_reviewing": "synthetic-steward",
        }
        write_json(submission_path, submission)

        candidate_path = prepare_candidate(
            submission_path=submission_path,
            workspace=workspace,
            node_id="human-space-monkey-one",
            identity_mode="stable_pseudonym",
            location_precision="country",
            location_label="Exampleland",
            country_code="EX",
            display_name="Space Monkey One",
            public_statement="I choose to be visible enough to cooperate and correct myself.",
            affirmed_at="2026-08-25T20:01:00+00:00",
            participant_consent=True,
        )
        first = load_json(candidate_path)
        assert_valid_declaration(first)
        if submission["reply_contact"] in candidate_path.read_text(encoding="utf-8"):
            raise AssertionError("private reply contact leaked into public candidate")

        duplicate_rejected = False
        try:
            prepare_candidate(
                submission_path=submission_path,
                workspace=workspace,
                node_id="human-space-monkey-duplicate",
                identity_mode="stable_pseudonym",
                location_precision="country",
                location_label="Exampleland",
                country_code="EX",
                display_name="Space Monkey Duplicate",
                public_statement=None,
                affirmed_at="2026-08-25T20:02:00+00:00",
                participant_consent=True,
            )
        except ValueError as exc:
            duplicate_rejected = "duplicate pilot source record" in str(exc)
        if not duplicate_rejected:
            raise AssertionError("duplicate source-record handling did not reject the second candidate")

        # Exercise all three steward states without giving any of them publication power.
        record_decision(workspace, first["node_id"], "pause", "synthetic-steward", "clarify public statement")
        record_decision(workspace, first["node_id"], "reject", "synthetic-steward", "synthetic rejection-path test")
        record_decision(workspace, first["node_id"], "approve", "synthetic-steward", "candidate may proceed to a separate publication gate")

        corrected_path = correct_candidate(
            workspace=workspace,
            node_id=first["node_id"],
            display_name=None,
            location_label=None,
            public_statement="I choose to be visible enough to cooperate, receive correction, and correct myself.",
            affirmed_at="2026-08-25T20:03:00+00:00",
            participant_affirmed=True,
        )
        corrected = load_json(corrected_path)
        assert_valid_declaration(corrected)
        if corrected["provenance"]["record_version"] != 2:
            raise AssertionError("correction did not create version 2")
        if decision_history(workspace, first["node_id"])[-1]["decision"] != "pause":
            raise AssertionError("correction did not force fresh steward review")

        record_decision(workspace, first["node_id"], "approve", "synthetic-steward", "corrected candidate reviewed")
        withdrawn_path, withdrawal_event_path = withdraw_candidate(
            workspace=workspace,
            node_id=first["node_id"],
            statement="I withdraw this public declaration candidate.",
            affirmed_at="2026-08-25T20:04:00+00:00",
            participant_affirmed=True,
        )
        withdrawn = load_json(withdrawn_path)
        event = load_json(withdrawal_event_path)
        assert_valid_declaration(withdrawn)
        assert_valid_event(event)
        if withdrawn["lifecycle"]["status"] != "withdrawn":
            raise AssertionError("withdrawal lifecycle state not applied")
        if withdrawn["provenance"]["record_version"] != 3:
            raise AssertionError("withdrawal did not create version 3")
        if event["authorship"]["actor_node_id"] != first["node_id"]:
            raise AssertionError("withdrawal event actor mismatch")

        # H1 has no publication path: all generated artifacts stay under the supplied workspace.
        generated = [p for p in temp.rglob("*") if p.is_file() and p != submission_path]
        if not generated or any(workspace not in p.parents for p in generated):
            raise AssertionError("H1 generated an artifact outside its private workspace")

        print("Human Mesh H1 synthetic lifecycle OK")
        print("prepare -> duplicate reject -> pause/reject/approve -> correction -> fresh pause -> approve -> withdrawal")
        print("No public file was created and private reply contact did not leak into the candidate declaration.")


def command_prepare(args) -> None:
    path = prepare_candidate(
        submission_path=pathlib.Path(args.submission),
        workspace=pathlib.Path(args.workspace),
        node_id=args.node_id,
        identity_mode=args.identity_mode,
        location_precision=args.location_precision,
        location_label=args.location_label,
        country_code=args.country_code,
        display_name=args.display_name,
        public_statement=args.public_statement,
        affirmed_at=args.affirmed_at,
        participant_consent=args.participant_consent,
    )
    print(path)


def command_decide(args) -> None:
    print(json.dumps(record_decision(pathlib.Path(args.workspace), args.node_id, args.decision, args.steward, args.reason), indent=2))


def command_correct(args) -> None:
    path = correct_candidate(
        workspace=pathlib.Path(args.workspace),
        node_id=args.node_id,
        display_name=args.display_name,
        location_label=args.location_label,
        public_statement=args.public_statement,
        affirmed_at=args.affirmed_at,
        participant_affirmed=args.participant_affirmed,
    )
    print(path)


def command_withdraw(args) -> None:
    declaration, event = withdraw_candidate(
        workspace=pathlib.Path(args.workspace),
        node_id=args.node_id,
        statement=args.statement,
        affirmed_at=args.affirmed_at,
        participant_affirmed=args.participant_affirmed,
    )
    print(declaration)
    print(event)


def command_status(args) -> None:
    path, candidate = latest_candidate(pathlib.Path(args.workspace), args.node_id)
    output = {
        "candidate_file": str(path),
        "node_id": args.node_id,
        "record_version": candidate["provenance"]["record_version"],
        "lifecycle": candidate["lifecycle"]["status"],
        "decision_history": decision_history(pathlib.Path(args.workspace), args.node_id),
        "publication": "not_authorized",
    }
    print(json.dumps(output, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="GroundMesh Human Mesh H1 local pilot lifecycle bridge")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("dry-run", help="run the full synthetic H1 lifecycle in a temporary workspace")

    prepare = sub.add_parser("prepare", help="create a private Human Mesh candidate from an existing pilot submission")
    prepare.add_argument("--submission", required=True)
    prepare.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    prepare.add_argument("--node-id", default="auto")
    prepare.add_argument("--identity-mode", choices=["public_name", "stable_pseudonym"], required=True)
    prepare.add_argument("--display-name")
    prepare.add_argument("--location-precision", choices=["country", "region", "city"], required=True)
    prepare.add_argument("--location-label", required=True)
    prepare.add_argument("--country-code")
    prepare.add_argument("--public-statement")
    prepare.add_argument("--affirmed-at", default=utc_now())
    prepare.add_argument("--participant-consent", action="store_true", help="attest that the participant explicitly approved the selected public fields and H0 consent terms")

    decide = sub.add_parser("decide", help="record a private steward decision; never publishes")
    decide.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    decide.add_argument("--node-id", required=True)
    decide.add_argument("--decision", choices=sorted(DECISIONS), required=True)
    decide.add_argument("--steward", default="local-steward")
    decide.add_argument("--reason", default="")

    correct = sub.add_parser("correct", help="record participant-approved correction as a new candidate version")
    correct.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    correct.add_argument("--node-id", required=True)
    correct.add_argument("--display-name")
    correct.add_argument("--location-label")
    correct.add_argument("--public-statement")
    correct.add_argument("--affirmed-at", default=utc_now())
    correct.add_argument("--participant-affirmed", action="store_true")

    withdraw = sub.add_parser("withdraw", help="withdraw a candidate and create a private self-authored withdrawal-event draft")
    withdraw.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    withdraw.add_argument("--node-id", required=True)
    withdraw.add_argument("--statement", required=True)
    withdraw.add_argument("--affirmed-at", default=utc_now())
    withdraw.add_argument("--participant-affirmed", action="store_true")

    status = sub.add_parser("status", help="show local candidate lifecycle and steward decision history")
    status.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    status.add_argument("--node-id", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "dry-run":
            run_dry_run()
        elif args.command == "prepare":
            command_prepare(args)
        elif args.command == "decide":
            command_decide(args)
        elif args.command == "correct":
            command_correct(args)
        elif args.command == "withdraw":
            command_withdraw(args)
        elif args.command == "status":
            command_status(args)
        else:
            raise ValueError(f"unknown command: {args.command}")
    except Exception as exc:
        print(f"Human Mesh H1 error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
