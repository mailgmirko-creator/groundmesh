#!/usr/bin/env python3
import json
import pathlib
import re
import sys

from jsonschema import Draft202012Validator, FormatChecker


FORBIDDEN_KEY_PATTERNS = [
    r"(^|_)score($|_)",
    r"(^|_)rank($|_)",
    r"(^|_)rating($|_)",
    r"trust_score",
    r"virtue",
    r"darkness",
    r"guilt",
    r"(^|_)sin($|_)",
    r"passport",
    r"government.*id",
    r"national.*id",
    r"identity.*number",
    r"(^|_)email($|_)",
    r"(^|_)phone($|_)",
    r"(^|_)address($|_)",
    r"latitude",
    r"longitude",
    r"(^|_)lat($|_)",
    r"(^|_)lon($|_)",
    r"birth",
    r"biometric",
    r"medical",
    r"health",
    r"religion",
    r"politic",
    r"ethnic",
    r"(^|_)race($|_)",
    r"criminal",
    r"sexual",
]


def iter_keys(value, path="$"):
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}.{key}"
            yield key, child_path
            yield from iter_keys(child, child_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from iter_keys(child, f"{path}[{index}]")


def forbidden_field_errors(record):
    errors = []
    for key, path in iter_keys(record):
        normalized = key.lower().replace("-", "_")
        for pattern in FORBIDDEN_KEY_PATTERNS:
            if re.search(pattern, normalized):
                errors.append(f"forbidden public-record field at {path}: {key}")
                break
    return errors


def validate_declaration_semantics(record):
    errors = forbidden_field_errors(record)

    identity = record.get("public_identity", {})
    if identity.get("identity_mode") == "stable_pseudonym" and identity.get("continuity_acknowledged") is not True:
        errors.append("stable pseudonym requires continuity_acknowledged=true")

    location = record.get("location", {})
    if location.get("precision") not in {"country", "region", "city"}:
        errors.append("public location precision must be country, region, or city")

    consent = record.get("consent", {})
    required_true = ["public_fields", "location_precision", "provenance_history", "right_to_correct_withdraw"]
    for field in required_true:
        if consent.get(field) is not True:
            errors.append(f"consent.{field} must be true")

    if consent.get("rules_version") != "human-mesh-foundation-v0.1":
        errors.append("consent.rules_version must be human-mesh-foundation-v0.1")

    commitments = set(record.get("accountability_commitments", []))
    if "avoid_person_scoring" not in commitments:
        errors.append("foundation declarations must include accountability commitment avoid_person_scoring")

    return errors


def validate_event_semantics(record):
    errors = forbidden_field_errors(record)
    authorship = record.get("authorship", {})
    if authorship.get("self_authored") is not True:
        errors.append("accountability events must be self-authored")
    if authorship.get("actor_node_id") != record.get("node_id"):
        errors.append("accountability event actor_node_id must equal node_id")
    if record.get("visibility") != "public_by_consent":
        errors.append("accountability event visibility must be public_by_consent")
    return errors


def validate_one(path, schema_path, semantic_fn, label):
    if not path.is_file():
        return [f"missing {label}: {path}"]
    if not schema_path.is_file():
        return [f"missing schema: {schema_path}"]

    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    record = json.loads(path.read_text(encoding="utf-8"))

    errors = []
    for error in sorted(validator.iter_errors(record), key=lambda e: list(e.absolute_path)):
        where = ".".join(str(part) for part in error.absolute_path) or "$"
        errors.append(f"schema {where}: {error.message}")
    errors.extend(f"semantic: {error}" for error in semantic_fn(record))
    return errors


def main():
    declaration_path = pathlib.Path("docs/human-mesh/examples/synthetic-human.json")
    declaration_schema = pathlib.Path("docs/human-mesh/schema/v0.1.schema.json")
    event_path = pathlib.Path("docs/human-mesh/examples/synthetic-accountability-event.json")
    event_schema = pathlib.Path("docs/human-mesh/schema/accountability-event.v0.1.schema.json")

    checks = [
        (declaration_path, declaration_schema, validate_declaration_semantics, "declaration"),
        (event_path, event_schema, validate_event_semantics, "accountability event"),
    ]

    failed = False
    for path, schema_path, semantic_fn, label in checks:
        errors = validate_one(path, schema_path, semantic_fn, label)
        if errors:
            failed = True
            print(f"Human Mesh validation errors in {path}:")
            for error in errors:
                print(f"- {error}")
        else:
            print(f"Human Mesh {label} OK: {path}")

    if failed:
        return 1
    print("Human Mesh foundation validation OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
