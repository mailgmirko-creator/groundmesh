#!/usr/bin/env python3
"""GroundMesh Human Mesh H1-H3 local lifecycle bridge.

This intentionally has no publish command. It reads an existing local registration
submission, creates only a participant-approved public candidate draft, and keeps
candidates, steward decisions, accountability-event drafts, and the H3 steward roster
inside the gitignored local pilot workspace.

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
STEWARD_ROLES = {"reviewer", "intake"}
STEWARD_ID_RE = re.compile(r"^steward-[a-z0-9][a-z0-9-]{1,62}$")
STEWARD_TERMS_VERSION = "human-mesh-h3-steward-role-v0.1"
STEWARD_ACCEPTANCE_KINDS = {"human_explicit", "synthetic_fixture"}
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
        "stewards": workspace / "stewards.json",
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


def empty_steward_roster() -> dict:
    return {"version": 1, "stewards": []}


def load_steward_roster(workspace: pathlib.Path) -> dict:
    path = workspace_paths(workspace)["stewards"]
    if not path.is_file():
        return empty_steward_roster()
    roster = load_json(path)
    if roster.get("version") != 1 or not isinstance(roster.get("stewards"), list):
        raise ValueError("private steward roster is malformed")
    return roster


def save_steward_roster(workspace: pathlib.Path, roster: dict) -> None:
    write_json(workspace_paths(workspace)["stewards"], roster)


def normalize_steward_id(steward_id: str) -> str:
    steward_id = steward_id.strip().lower()
    if not STEWARD_ID_RE.fullmatch(steward_id):
        raise ValueError("steward id must match steward-<lowercase-stable-id>")
    return steward_id


def make_steward_acceptance(acceptance_kind: str, acceptance_attested: bool, now: str) -> dict:
    if acceptance_attested is not True:
        raise ValueError(
            "steward roles require explicit acceptance; record the role only after the person directly accepts the current H3 steward terms"
        )
    if acceptance_kind not in STEWARD_ACCEPTANCE_KINDS:
        raise ValueError(f"unsupported steward acceptance kind: {acceptance_kind}")
    basis = "operator_attested_direct_acceptance" if acceptance_kind == "human_explicit" else "synthetic_fixture"
    return {
        "explicit": True,
        "kind": acceptance_kind,
        "recorded_at": now,
        "recorded_basis": basis,
        "terms_version": STEWARD_TERMS_VERSION,
    }


def steward_has_current_acceptance(steward: dict) -> bool:
    acceptance = steward.get("acceptance")
    return bool(
        isinstance(acceptance, dict)
        and acceptance.get("explicit") is True
        and acceptance.get("kind") in STEWARD_ACCEPTANCE_KINDS
        and acceptance.get("terms_version") == STEWARD_TERMS_VERSION
    )


def register_steward(
    workspace: pathlib.Path,
    steward_id: str,
    display_label: str,
    roles: list[str],
    acceptance_kind: str,
    acceptance_attested: bool,
) -> dict:
    steward_id = normalize_steward_id(steward_id)
    display_label = display_label.strip()[:100]
    if not display_label:
        raise ValueError("steward display label is required")
    normalized_roles = sorted(set(roles))
    if not normalized_roles or any(role not in STEWARD_ROLES for role in normalized_roles):
        raise ValueError(f"steward roles must be drawn from: {', '.join(sorted(STEWARD_ROLES))}")

    roster = load_steward_roster(workspace)
    now = utc_now()
    acceptance = make_steward_acceptance(acceptance_kind, acceptance_attested, now)
    found = None
    for item in roster["stewards"]:
        if item.get("steward_id") == steward_id:
            found = item
            break

    if found is None:
        found = {
            "steward_id": steward_id,
            "display_label": display_label,
            "roles": normalized_roles,
            "active": True,
            "acceptance": acceptance,
            "created_at": now,
            "updated_at": now,
        }
        roster["stewards"].append(found)
    else:
        found["display_label"] = display_label
        found["roles"] = normalized_roles
        found["active"] = True
        found["acceptance"] = acceptance
        found["updated_at"] = now

    roster["stewards"] = sorted(roster["stewards"], key=lambda item: item["steward_id"])
    save_steward_roster(workspace, roster)
    return found


def deactivate_steward(workspace: pathlib.Path, steward_id: str) -> dict:
    steward_id = normalize_steward_id(steward_id)
    roster = load_steward_roster(workspace)
    for item in roster["stewards"]:
        if item.get("steward_id") == steward_id:
            item["active"] = False
            item["updated_at"] = utc_now()
            save_steward_roster(workspace, roster)
            return item
    raise ValueError(f"unknown steward id: {steward_id}")


def require_active_steward(workspace: pathlib.Path, steward_id: str, role: str) -> dict:
    steward_id = normalize_steward_id(steward_id)
    roster = load_steward_roster(workspace)
    for item in roster["stewards"]:
        if item.get("steward_id") != steward_id:
            continue
        if item.get("active") is not True:
            raise ValueError(f"steward is inactive: {steward_id}")
        if not steward_has_current_acceptance(item):
            raise ValueError(
                f"steward has no recorded explicit acceptance of {STEWARD_TERMS_VERSION}: {steward_id}; re-add only after direct acceptance"
            )
        if role not in item.get("roles", []):
            raise ValueError(f"steward {steward_id} lacks required role: {role}")
        return item
    raise ValueError(f"unknown steward id: {steward_id}")


def active_reviewer_count(workspace: pathlib.Path) -> int:
    roster = load_steward_roster(workspace)
    return sum(
        1
        for item in roster["stewards"]
        if item.get("active") is True and "reviewer" in item.get("roles", []) and steward_has_current_acceptance(item)
    )


def active_human_reviewer_count(workspace: pathlib.Path) -> int:
    roster = load_steward_roster(workspace)
    return sum(
        1
        for item in roster["stewards"]
        if item.get("active") is True
        and "reviewer" in item.get("roles", [])
        and steward_has_current_acceptance(item)
        and item["acceptance"].get("kind") == "human_explicit"
    )


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
            "created_by": "GroundMesh H1-H3 local pilot bridge",
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


def record_decision(workspace: pathlib.Path, node_id: str, decision: str, steward_id: str, reason: str) -> dict:
    if decision not in DECISIONS:
        raise ValueError(f"decision must be one of: {', '.join(sorted(DECISIONS))}")
    steward = require_active_steward(workspace, steward_id, "reviewer")
    _, candidate = latest_candidate(workspace, node_id)
    event = {
        "at": utc_now(),
        "type": "steward_decision",
        "node_id": node_id,
        "record_version": candidate["provenance"]["record_version"],
        "decision": decision,
        "steward_id": steward["steward_id"],
        "steward_label": steward["display_label"],
        "reason": reason.strip()[:1000],
        "publication": "not_authorized",
    }
    append_jsonl(workspace_paths(workspace)["decisions"] / f"{node_id}.jsonl", event)
    return event


def record_system_pause(workspace: pathlib.Path, node_id: str, reason: str) -> dict:
    _, candidate = latest_candidate(workspace, node_id)
    event = {
        "at": utc_now(),
        "type": "system_hold",
        "node_id": node_id,
        "record_version": candidate["provenance"]["record_version"],
        "decision": "pause",
        "actor": "system",
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
        "created_by": "GroundMesh H1-H3 participant correction bridge",
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
    record_system_pause(workspace, node_id, "participant correction requires fresh steward review")
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
        "created_by": "GroundMesh H1-H3 participant withdrawal bridge",
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
    with tempfile.TemporaryDirectory(prefix="groundmesh-human-mesh-h1-h3-") as raw:
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
            "note": "Synthetic H1/H3 fixture only.",
            "consent_ordinary_email_only": True,
            "record_id": "participant-0001",
            "received_at": "2026-08-25T20:00:00+00:00",
            "steward_reviewing": "unassigned",
        }
        write_json(submission_path, submission)

        missing_acceptance_rejected = False
        try:
            register_steward(
                workspace,
                "steward-unaccepted-cli-shape",
                "Must Not Be Added",
                ["reviewer"],
                "human_explicit",
                False,
            )
        except ValueError as exc:
            missing_acceptance_rejected = "explicit acceptance" in str(exc)
        if not missing_acceptance_rejected:
            raise AssertionError("H3 allowed steward registration without explicit role acceptance")

        reviewer_a = register_steward(
            workspace,
            "steward-synthetic-a",
            "Synthetic Reviewer A",
            ["reviewer", "intake"],
            "synthetic_fixture",
            True,
        )
        reviewer_b = register_steward(
            workspace,
            "steward-synthetic-b",
            "Synthetic Reviewer B",
            ["reviewer"],
            "synthetic_fixture",
            True,
        )
        register_steward(
            workspace,
            "steward-intake-only",
            "Synthetic Intake Only",
            ["intake"],
            "synthetic_fixture",
            True,
        )
        register_steward(
            workspace,
            "steward-inactive",
            "Synthetic Inactive Reviewer",
            ["reviewer"],
            "synthetic_fixture",
            True,
        )
        deactivate_steward(workspace, "steward-inactive")

        roster = load_steward_roster(workspace)
        now = utc_now()
        roster["stewards"].append(
            {
                "steward_id": "steward-legacy-unaccepted",
                "display_label": "Legacy Unaccepted Reviewer",
                "roles": ["reviewer"],
                "active": True,
                "created_at": now,
                "updated_at": now,
            }
        )
        save_steward_roster(workspace, roster)

        if active_reviewer_count(workspace) != 2:
            raise AssertionError("H3 accepted-reviewer count should ignore inactive and unaccepted roster entries")
        if active_human_reviewer_count(workspace) != 0:
            raise AssertionError("synthetic reviewers must not count as real-human operational plurality")

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

        pause = record_decision(workspace, first["node_id"], "pause", reviewer_a["steward_id"], "clarify public statement")
        reject = record_decision(workspace, first["node_id"], "reject", reviewer_b["steward_id"], "synthetic rejection-path test")
        approve = record_decision(workspace, first["node_id"], "approve", reviewer_b["steward_id"], "candidate may proceed to a separate publication gate")
        if pause["steward_id"] == approve["steward_id"]:
            raise AssertionError("H3 plurality test did not exercise two distinct reviewers")
        if any(item["publication"] != "not_authorized" for item in (pause, reject, approve)):
            raise AssertionError("steward decision unexpectedly granted publication authority")

        for unauthorized_id in (
            "steward-unknown",
            "steward-inactive",
            "steward-intake-only",
            "steward-legacy-unaccepted",
        ):
            rejected = False
            try:
                record_decision(workspace, first["node_id"], "approve", unauthorized_id, "must fail")
            except ValueError:
                rejected = True
            if not rejected:
                raise AssertionError(f"unauthorized reviewer was allowed to act: {unauthorized_id}")

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

        record_decision(workspace, first["node_id"], "approve", reviewer_a["steward_id"], "corrected candidate reviewed")
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

        generated = [p for p in temp.rglob("*") if p.is_file() and p != submission_path]
        if not generated or any(workspace not in p.parents for p in generated):
            raise AssertionError("Human Mesh lifecycle generated an artifact outside its private workspace")

        history = decision_history(workspace, first["node_id"])
        steward_ids = {item.get("steward_id") for item in history if item.get("type") == "steward_decision"}
        if not {reviewer_a["steward_id"], reviewer_b["steward_id"]}.issubset(steward_ids):
            raise AssertionError("decision provenance does not show both active reviewers")

        print("Human Mesh H1/H3 synthetic lifecycle OK")
        print("two explicitly accepted synthetic reviewers -> bounded decisions -> unauthorized rejection -> correction -> fresh review -> withdrawal")
        print("Synthetic reviewers do not count as real-human operational plurality.")
        print("No public file was created; all steward decisions remain publication:not_authorized.")


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
    print(json.dumps(record_decision(pathlib.Path(args.workspace), args.node_id, args.decision, args.steward_id, args.reason), indent=2))


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
    workspace = pathlib.Path(args.workspace)
    path, candidate = latest_candidate(workspace, args.node_id)
    reviewers = active_reviewer_count(workspace)
    human_reviewers = active_human_reviewer_count(workspace)
    output = {
        "candidate_file": str(path),
        "node_id": args.node_id,
        "record_version": candidate["provenance"]["record_version"],
        "lifecycle": candidate["lifecycle"]["status"],
        "decision_history": decision_history(workspace, args.node_id),
        "active_reviewer_count": reviewers,
        "active_human_reviewer_count": human_reviewers,
        "operational_plurality_capable": human_reviewers >= 2,
        "publication": "not_authorized",
    }
    print(json.dumps(output, indent=2))


def command_steward_add(args) -> None:
    steward = register_steward(
        pathlib.Path(args.workspace),
        args.steward_id,
        args.label,
        args.role,
        "human_explicit",
        args.accepted_by_human,
    )
    print(json.dumps(steward, indent=2))


def command_steward_deactivate(args) -> None:
    steward = deactivate_steward(pathlib.Path(args.workspace), args.steward_id)
    print(json.dumps(steward, indent=2))


def command_steward_list(args) -> None:
    workspace = pathlib.Path(args.workspace)
    roster = load_steward_roster(workspace)
    reviewer_count = active_reviewer_count(workspace)
    human_reviewer_count = active_human_reviewer_count(workspace)
    print(json.dumps({
        **roster,
        "active_reviewer_count": reviewer_count,
        "active_human_reviewer_count": human_reviewer_count,
        "operational_plurality_capable": human_reviewer_count >= 2,
    }, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="GroundMesh Human Mesh H1-H3 local lifecycle bridge")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("dry-run", help="run the full synthetic H1/H3 lifecycle in a temporary workspace")

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

    decide = sub.add_parser("decide", help="record a private decision by an active, explicitly accepted rostered reviewer; never publishes")
    decide.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    decide.add_argument("--node-id", required=True)
    decide.add_argument("--decision", choices=sorted(DECISIONS), required=True)
    decide.add_argument("--steward-id", "--steward", dest="steward_id", required=True)
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

    status = sub.add_parser("status", help="show local candidate lifecycle, decision history, and reviewer capacity")
    status.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    status.add_argument("--node-id", required=True)

    steward_add = sub.add_parser("steward-add", help="add or reactivate a private H3 steward after explicit human role acceptance")
    steward_add.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    steward_add.add_argument("--steward-id", required=True)
    steward_add.add_argument("--label", required=True)
    steward_add.add_argument("--role", action="append", choices=sorted(STEWARD_ROLES), required=True)
    steward_add.add_argument(
        "--accepted-by-human",
        action="store_true",
        help=f"attest that the steward directly and explicitly accepted the assigned roles under {STEWARD_TERMS_VERSION}",
    )

    steward_deactivate = sub.add_parser("steward-deactivate", help="deactivate a private H3 steward without deleting provenance")
    steward_deactivate.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
    steward_deactivate.add_argument("--steward-id", required=True)

    steward_list = sub.add_parser("steward-list", help="show the private H3 steward roster and accepted real-human reviewer capacity")
    steward_list.add_argument("--workspace", default=str(DEFAULT_WORKSPACE))
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
        elif args.command == "steward-add":
            command_steward_add(args)
        elif args.command == "steward-deactivate":
            command_steward_deactivate(args)
        elif args.command == "steward-list":
            command_steward_list(args)
        else:
            raise ValueError(f"unknown command: {args.command}")
    except Exception as exc:
        print(f"Human Mesh lifecycle error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
