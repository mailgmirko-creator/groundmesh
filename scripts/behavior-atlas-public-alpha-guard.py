#!/usr/bin/env python3
import datetime as dt
import json
import pathlib
import re
import sys


def fail(errors):
    print("M4 public-alpha guard failed:")
    for error in errors:
        print(f"- {error}")
    raise SystemExit(1)


manifest_path = pathlib.Path("docs/behavior-atlas/releases/m4-public-alpha-v0.1.json")
required_paths = [
    pathlib.Path("docs/behavior-atlas/index.html"),
    pathlib.Path("docs/behavior-atlas/PUBLIC_ALPHA_POLICY.md"),
    pathlib.Path("docs/behavior-atlas/PRIVACY_HARM_REVIEW.md"),
    pathlib.Path("docs/behavior-atlas/CHANGELOG.md"),
    manifest_path,
    pathlib.Path("scripts/behavior-atlas-restore-drill.ps1"),
]
missing_paths = [str(path) for path in required_paths if not path.is_file()]
if missing_paths:
    fail([f"missing required file: {path}" for path in missing_paths])

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
errors = []

if manifest.get("stage") != "public_alpha":
    errors.append("release manifest stage must be public_alpha")
if manifest.get("evidence_state") != "sourced_not_independently_adjudicated":
    errors.append("release manifest must preserve sourced/not-independently-adjudicated evidence state")
if manifest.get("single_reviewer_warning_required") is not True:
    errors.append("release manifest must require the single-reviewer warning")

rollback_ref = str(manifest.get("rollback_ref", ""))
if not re.fullmatch(r"[a-f0-9]{40}", rollback_ref):
    errors.append("rollback_ref must be a full 40-character Git SHA")

cases = manifest.get("cases", [])
if len(cases) < 3:
    errors.append("M4 public alpha requires at least three cases")

today = dt.date.today()
index_path = pathlib.Path("docs/behavior-atlas/index.html")
index_html = index_path.read_text(encoding="utf-8")
for marker in [
    "M4 Public Alpha",
    "single-reviewer warning",
    "Corrections are part of the system",
    "no person scoring",
]:
    if marker.lower() not in index_html.lower():
        errors.append(f"public front door missing marker: {marker}")

for case in cases:
    case_id = case.get("case_id", "unknown-case")
    public_path = pathlib.Path(case.get("public_path", ""))
    source_bundle = pathlib.Path(case.get("source_bundle", ""))

    if not public_path.is_file():
        errors.append(f"missing public case page: {public_path}")
        continue
    if not source_bundle.is_file():
        errors.append(f"missing source bundle: {source_bundle}")

    try:
        review_due = dt.date.fromisoformat(case["review_due"])
    except Exception:
        errors.append(f"invalid review_due for {case_id}")
        continue
    if review_due < today:
        errors.append(f"already-expired review_due for {case_id}: {review_due}")

    html = public_path.read_text(encoding="utf-8")
    if "noindex" in html.lower():
        errors.append(f"public-alpha page still carries noindex: {public_path}")
    for marker in [
        "Public Alpha",
        "Single-reviewer warning",
        "Submit a correction",
        "footprint, not the soul",
        "Assessment review due",
    ]:
        if marker.lower() not in html.lower():
            errors.append(f"{public_path} missing marker: {marker}")
    if case["review_due"] not in html:
        errors.append(f"{public_path} does not embed review_due {case['review_due']}")

    relative_public = public_path.relative_to("docs/behavior-atlas").as_posix()
    if relative_public not in index_html:
        errors.append(f"public front door does not link case: {relative_public}")

policy = pathlib.Path("docs/behavior-atlas/PUBLIC_ALPHA_POLICY.md").read_text(encoding="utf-8")
for marker in ["Review-due and expiry rule", "Withdrawal and rollback", "Human responsibility"]:
    if marker not in policy:
        errors.append(f"public-alpha policy missing section: {marker}")

harm = pathlib.Path("docs/behavior-atlas/PRIVACY_HARM_REVIEW.md").read_text(encoding="utf-8")
for marker in ["Privacy and Harm Review", "Residual risk", "Release decision"]:
    if marker.lower() not in harm.lower():
        errors.append(f"privacy/harm review missing marker: {marker}")

changelog = pathlib.Path("docs/behavior-atlas/CHANGELOG.md").read_text(encoding="utf-8")
if "M4 public alpha v0.1" not in changelog:
    errors.append("Behavior Atlas changelog missing M4 public alpha v0.1 entry")

registry = json.loads(pathlib.Path("docs/atlas/registry.json").read_text(encoding="utf-8"))
atlas_entry = next((entry for entry in registry.get("entries", []) if entry.get("id") == "PAGE-BEHAVIOR-ATLAS"), None)
if not atlas_entry:
    errors.append("Project Atlas registry missing PAGE-BEHAVIOR-ATLAS")
elif atlas_entry.get("path") != "docs/behavior-atlas/index.html" or atlas_entry.get("status") != "active":
    errors.append("PAGE-BEHAVIOR-ATLAS registry entry must be active and point to docs/behavior-atlas/index.html")

atlas_html = pathlib.Path("docs/atlas/index.html").read_text(encoding="utf-8")
if "PAGE-BEHAVIOR-ATLAS" not in atlas_html or "../behavior-atlas/index.html" not in atlas_html:
    errors.append("generated Project Atlas index does not expose PAGE-BEHAVIOR-ATLAS")

# The public release manifest must not expose the direct routes of the historical
# unlisted previews. Their existence is verified by the restore drill instead.
manifest_text = manifest_path.read_text(encoding="utf-8")
if "behavior-atlas/preview/" in manifest_text:
    errors.append("public release manifest exposes an unlisted preview route")

if errors:
    fail(errors)

print(f"M4 public-alpha guard OK ({len(cases)} cases; review dates current)")
