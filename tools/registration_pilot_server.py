from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DOCS_ROOT = ROOT / "docs"
PRIVATE_ROOT = ROOT / "private" / "registration_pilot"
RECORDS_ROOT = PRIVATE_ROOT / "records"
SUBMISSIONS_ROOT = PRIVATE_ROOT / "submissions"
LOG_PATH = PRIVATE_ROOT / "interest-log.jsonl"

REQUIRED_FIELDS = {
    "display_name": 80,
    "region_or_country": 80,
    "participation_type": 80,
    "reply_contact": 120,
    "contact_preference": 80,
    "privacy_request": 80,
}

OPTIONAL_FIELDS = {
    "note": 500,
}


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "participant"


def ensure_private_dirs() -> None:
    RECORDS_ROOT.mkdir(parents=True, exist_ok=True)
    SUBMISSIONS_ROOT.mkdir(parents=True, exist_ok=True)


def existing_numbers() -> list[int]:
    pattern = re.compile(r"participant-(\d{4})-[a-z0-9-]+\.md$")
    numbers: list[int] = []
    if RECORDS_ROOT.exists():
      for path in RECORDS_ROOT.glob("participant-*.md"):
        if path.name.endswith("-draft.md"):
            continue
        match = pattern.match(path.name)
        if match:
            numbers.append(int(match.group(1)))
    return numbers


def next_record_id() -> str:
    return f"participant-{max(existing_numbers(), default=0) + 1:04d}"


def clean_value(value: object, max_len: int) -> str:
    text = str(value or "").strip()
    return text[:max_len]


def validate_payload(payload: dict[str, object]) -> tuple[dict[str, object], list[str]]:
    cleaned: dict[str, object] = {}
    errors: list[str] = []

    for key, max_len in REQUIRED_FIELDS.items():
        cleaned[key] = clean_value(payload.get(key), max_len)
        if not cleaned[key]:
            errors.append(f"{key} is required")

    for key, max_len in OPTIONAL_FIELDS.items():
        cleaned[key] = clean_value(payload.get(key), max_len)

    consent = bool(payload.get("consent_ordinary_email_only"))
    cleaned["consent_ordinary_email_only"] = consent
    if not consent:
        errors.append("consent_ordinary_email_only must be accepted")

    return cleaned, errors


def render_record(record: dict[str, object]) -> str:
    lines = [
        f"# {record['record_id']} - {record['display_name']}",
        "",
        "## Record",
        f"- Record ID: {record['record_id']}",
        f"- Date received: {record['received_at']}",
        f"- Steward reviewing: {record['steward_reviewing']}",
        "- Current status: received",
        "",
        "## Participant signal",
        f"- Display or chosen name: {record['display_name']}",
        f"- Region or country: {record['region_or_country']}",
        f"- Participation type: {record['participation_type']}",
        f"- Reply email or handle: {record['reply_contact']}",
        f"- Contact preference: {record['contact_preference']}",
        f"- Privacy / declaration preference: {record['privacy_request']}",
        f"- Short note: {record['note']}",
        "",
        "## Consent and privacy",
        f"- Sender understood this was ordinary email, not a confidential intake channel: {'yes' if record['consent_ordinary_email_only'] else 'no'}",
        "- Any request for privacy, pseudonymity, or public declaration:",
        "- Any correction or removal request:",
        "",
        "## Triage outcome",
        "- Overshared sensitive material present: no",
        "- Clarification needed:",
        "- Smallest honest next step:",
        "",
        "## Steward notes",
        "- Minimal internal note:",
        "- Follow-up date:",
        "- Pause or escalation reason, if any:",
        "",
        "## Storage note",
        "- This record was created by the local registration pilot intake server.",
    ]
    return "\n".join(lines) + "\n"


class RegistrationPilotHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DOCS_ROOT), **kwargs)

    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        super().end_headers()

    def log_message(self, fmt: str, *args) -> None:
        print(fmt % args)

    def do_OPTIONS(self) -> None:
        if urlparse(self.path).path.startswith("/api/"):
            self.send_response(204)
            self.end_headers()
            return
        super().do_OPTIONS()

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/api/pilot-register/health":
            self._json_response(
                200,
                {
                    "ok": True,
                    "intake_active": True,
                    "storage_root": "private/registration_pilot/",
                },
            )
            return
        if path == "/":
            self.path = "/index.html"
        super().do_GET()

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        if path != "/api/pilot-register":
            self._json_response(404, {"ok": False, "errors": ["Unknown API path"]})
            return

        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            content_length = 0

        try:
            raw_body = self.rfile.read(content_length).decode("utf-8")
            payload = json.loads(raw_body or "{}")
        except (UnicodeDecodeError, json.JSONDecodeError):
            self._json_response(400, {"ok": False, "errors": ["Invalid JSON payload"]})
            return

        cleaned, errors = validate_payload(payload)
        if errors:
            self._json_response(400, {"ok": False, "errors": errors})
            return

        ensure_private_dirs()
        record_id = next_record_id()
        timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
        slug = slugify(str(cleaned["display_name"]))
        record = {
            **cleaned,
            "record_id": record_id,
            "received_at": timestamp,
            "steward_reviewing": "Mirko Giljaca",
        }

        json_path = SUBMISSIONS_ROOT / f"{record_id}-{slug}.json"
        md_path = RECORDS_ROOT / f"{record_id}-{slug}.md"

        json_path.write_text(json.dumps(record, indent=2), encoding="utf-8")
        md_path.write_text(render_record(record), encoding="utf-8")
        with LOG_PATH.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps({"record_id": record_id, "received_at": timestamp, "type": "registration_interest"}) + "\n")

        self._json_response(
            201,
            {
                "ok": True,
                "record_id": record_id,
                "stored_at": timestamp,
                "record_file": str(md_path.relative_to(ROOT)).replace("\\", "/"),
            },
        )

    def _json_response(self, status_code: int, payload: dict[str, object]) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main() -> None:
    parser = argparse.ArgumentParser(description="GroundMesh invited-circle registration pilot server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8787)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), RegistrationPilotHandler)
    print(f"GroundMesh registration pilot server running at http://{args.host}:{args.port}/register-pilot.html")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
