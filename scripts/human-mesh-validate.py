#!/usr/bin/env python3
import copy
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


def load_schema(path):
    if not path.is_file():
        raise RuntimeError(f"missing schema: {path}")
    schema = json.loads(path.read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema, format_checker=FormatChecker())


def validate_record(record, validator, semantic_fn):
    errors = []
    for error in sorted(validator.iter_errors(record), key=lambda e: list(e.absolute_path)):
        where = ".".join(str(part) for part in error.absolute_path) or "$"
        errors.append(f"schema {where}: {error.message}")
    errors.extend(f"semantic: {error}" for error in semantic_fn(record))
    return errors


def validate_file(path, validator, semantic_fn, label):
    if not path.is_file():
        return [f"missing {label}: {path}"], None
    record = json.loads(path.read_text(encoding="utf-8"))
    return validate_record(record, validator, semantic_fn), record


def negative_self_tests(declaration, declaration_validator, event, event_validator):
    failures = []

    scored = copy.deepcopy(declaration)
    scored["trust_score"] = 99
    if not validate_record(scored, declaration_validator, validate_declaration_semantics):
        failures.append("negative test failed: trust_score was accepted")

    contacted = copy.deepcopy(declaration)
    contacted["private_email"] = "fictional@example.invalid"
    if not validate_record(contacted, declaration_validator, validate_declaration_semantics):
        failures.append("negative test failed: private_email was accepted")

    precise = copy.deepcopy(declaration)
    precise["location"]["latitude"] = 42.0
    precise["location"]["longitude"] = 18.0
    if not validate_record(precise, declaration_validator, validate_declaration_semantics):
        failures.append("negative test failed: precise public coordinates were accepted")

    not_self_authored = copy.deepcopy(event)
    not_self_authored["authorship"]["self_authored"] = False
    if not validate_record(not_self_authored, event_validator, validate_event_semantics):
        failures.append("negative test failed: non-self-authored accountability event was accepted")

    actor_mismatch = copy.deepcopy(event)
    actor_mismatch["authorship"]["actor_node_id"] = "human-someone-else"
    if not validate_record(actor_mismatch, event_validator, validate_event_semantics):
        failures.append("negative test failed: accountability actor mismatch was accepted")

    return failures


def main():
    declaration_path = pathlib.Path("docs/human-mesh/examples/synthetic-human.json")
    declaration_schema = pathlib.Path("docs/human-mesh/schema/v0.1.schema.json")
    event_path = pathlib.Path("docs/human-mesh/examples/synthetic-accountability-event.json")
    event_schema = pathlib.Path("docs/human-mesh/schema/accountability-event.v0.1.schema.json")

    try:
        declaration_validator = load_schema(declaration_schema)
        event_validator = load_schema(event_schema)
    except Exception as exc:
        print(f"Human Mesh schema error: {exc}")
        return 1

    failed = False

    declaration_errors, declaration = validate_file(
        declaration_path, declaration_validator, validate_declaration_semantics, "declaration"
    )
    if declaration_errors:
        failed = True
        print(f"Human Mesh validation errors in {declaration_path}:")
        for error in declaration_errors:
            print(f"- {error}")
    else:
        print(f"Human Mesh declaration OK: {declaration_path}")

    event_errors, event = validate_file(
        event_path, event_validator, validate_event_semantics, "accountability event"
    )
    if event_errors:
        failed = True
        print(f"Human Mesh validation errors in {event_path}:")
        for error in event_errors:
            print(f"- {error}")
    else:
        print(f"Human Mesh accountability event OK: {event_path}")

    if declaration is not None and event is not None:
        negative_failures = negative_self_tests(declaration, declaration_validator, event, event_validator)
        if negative_failures:
            failed = True
            print("Human Mesh negative guardrail tests failed:")
            for error in negative_failures:
                print(f"- {error}")
        else:
            print("Human Mesh negative guardrail tests OK")

    if failed:
        return 1
    print("Human Mesh foundation validation OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
