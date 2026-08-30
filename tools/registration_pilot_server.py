from __future__ import annotations

import argparse
import hashlib
import json
import re
import secrets
import tempfile
import threading
from datetime import datetime, timedelta, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DOCS_ROOT = ROOT / "docs"
DEFAULT_PRIVATE_ROOT = ROOT / "private" / "registration_pilot"
MAX_BODY_BYTES = 16 * 1024

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


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def iso_utc(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat()


def parse_datetime(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "participant"


def clean_value(value: object, max_len: int) -> str:
    return str(value or "").strip()[:max_len]


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


def invite_hash(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


class PilotState:
    def __init__(
        self,
        private_root: Path = DEFAULT_PRIVATE_ROOT,
        require_invite_code: bool = False,
        steward_name: str = "unassigned",
    ) -> None:
        self.private_root = private_root
        self.records_root = private_root / "records"
        self.submissions_root = private_root / "submissions"
        self.log_path = private_root / "interest-log.jsonl"
        self.invites_path = private_root / "invite-codes.json"
        self.require_invite_code = require_invite_code
        self.steward_name = steward_name
        self.lock = threading.Lock()

    def ensure_private_dirs(self) -> None:
        self.records_root.mkdir(parents=True, exist_ok=True)
        self.submissions_root.mkdir(parents=True, exist_ok=True)

    def existing_numbers(self) -> list[int]:
        pattern = re.compile(r"participant-(\d{4})-[a-z0-9-]+\.md$")
        numbers: list[int] = []
        if self.records_root.exists():
            for path in self.records_root.glob("participant-*.md"):
                if path.name.endswith("-draft.md"):
                    continue
                match = pattern.match(path.name)
                if match:
                    numbers.append(int(match.group(1)))
        return numbers

    def next_record_id(self) -> str:
        return f"participant-{max(self.existing_numbers(), default=0) + 1:04d}"


def empty_invite_registry() -> dict[str, object]:
    return {"version": 1, "invites": []}


def load_invite_registry(state: PilotState) -> dict[str, object]:
    if not state.invites_path.is_file():
        return empty_invite_registry()
    data = json.loads(state.invites_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("invites"), list):
        raise RuntimeError("invite registry is malformed")
    return data


def save_invite_registry(state: PilotState, registry: dict[str, object]) -> None:
    state.private_root.mkdir(parents=True, exist_ok=True)
    state.invites_path.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")


def generate_invites(
    state: PilotState,
    count: int,
    expires_days: int = 14,
    uses: int = 1,
    now: datetime | None = None,
) -> list[str]:
    if count < 1 or count > 100:
        raise ValueError("count must be between 1 and 100")
    if expires_days < 1 or expires_days > 365:
        raise ValueError("expires_days must be between 1 and 365")
    if uses < 1 or uses > 20:
        raise ValueError("uses must be between 1 and 20")

    now = now or utc_now()
    registry = load_invite_registry(state)
    invites = registry["invites"]
    assert isinstance(invites, list)

    plaintext_codes: list[str] = []
    for _ in range(count):
        code = "gmh2-" + secrets.token_urlsafe(12)
        plaintext_codes.append(code)
        invites.append(
            {
                "invite_id": "invite-" + secrets.token_hex(6),
                "sha256": invite_hash(code),
                "created_at": iso_utc(now),
                "expires_at": iso_utc(now + timedelta(days=expires_days)),
                "uses_remaining": uses,
                "status": "active",
            }
        )

    save_invite_registry(state, registry)
    return plaintext_codes


def find_usable_invite(
    registry: dict[str, object],
    code: str,
    now: datetime,
) -> tuple[dict[str, object] | None, str | None]:
    code = code.strip()
    if not code:
        return None, "invitation_code is required"

    digest = invite_hash(code)
    invites = registry.get("invites", [])
    if not isinstance(invites, list):
        return None, "invite registry is malformed"

    for item in invites:
        if not isinstance(item, dict):
            continue
        stored_hash = str(item.get("sha256", ""))
        if not stored_hash or not secrets.compare_digest(stored_hash, digest):
            continue
        if item.get("status") != "active":
            return None, "invitation code is no longer active"
        try:
            expires_at = parse_datetime(str(item.get("expires_at", "")))
        except Exception:
            return None, "invitation code has invalid expiry metadata"
        if now > expires_at:
            return None, "invitation code has expired"
        uses_remaining = int(item.get("uses_remaining", 0))
        if uses_remaining < 1:
            return None, "invitation code has already been used"
        return item, None

    return None, "invitation code is invalid"


def consume_invite(item: dict[str, object], now: datetime) -> None:
    remaining = int(item.get("uses_remaining", 0)) - 1
    item["uses_remaining"] = max(0, remaining)
    item["last_used_at"] = iso_utc(now)
    if remaining <= 0:
        item["status"] = "used"


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


def process_submission(
    payload: dict[str, object],
    state: PilotState,
    now: datetime | None = None,
) -> tuple[int, dict[str, object]]:
    now = now or utc_now()
    cleaned, errors = validate_payload(payload)
    if errors:
        return 400, {"ok": False, "errors": errors}

    invitation_code = clean_value(payload.get("invitation_code"), 160)

    with state.lock:
        state.ensure_private_dirs()

        registry: dict[str, object] | None = None
        invite_item: dict[str, object] | None = None
        if state.require_invite_code:
            registry = load_invite_registry(state)
            invite_item, invite_error = find_usable_invite(registry, invitation_code, now)
            if invite_error:
                return 403, {"ok": False, "errors": [invite_error]}

        record_id = state.next_record_id()
        timestamp = iso_utc(now)
        slug = slugify(str(cleaned["display_name"]))
        record = {
            **cleaned,
            "record_id": record_id,
            "received_at": timestamp,
            "steward_reviewing": state.steward_name,
        }

        json_path = state.submissions_root / f"{record_id}-{slug}.json"
        md_path = state.records_root / f"{record_id}-{slug}.md"

        # Invitation codes are admission secrets and are intentionally omitted from
        # participant records, rendered records, and the interest log.
        json_path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
        md_path.write_text(render_record(record), encoding="utf-8")
        with state.log_path.open("a", encoding="utf-8") as handle:
            handle.write(
                json.dumps(
                    {
                        "record_id": record_id,
                        "received_at": timestamp,
                        "type": "registration_interest",
                        "intake_mode": "limited_invitation" if state.require_invite_code else "trusted_circle",
                    }
                )
                + "\n"
            )

        if invite_item is not None and registry is not None:
            consume_invite(invite_item, now)
            save_invite_registry(state, registry)

    record_file = md_path.name
    try:
        record_file = str(md_path.relative_to(ROOT)).replace("\\", "/")
    except ValueError:
        pass

    return (
        201,
        {
            "ok": True,
            "record_id": record_id,
            "stored_at": timestamp,
            "record_file": record_file,
            "intake_mode": "limited_invitation" if state.require_invite_code else "trusted_circle",
        },
    )


def make_handler(state: PilotState):
    class RegistrationPilotHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(DOCS_ROOT), **kwargs)

        def end_headers(self) -> None:
            if urlparse(self.path).path.startswith("/api/"):
                self.send_header("Cache-Control", "no-store")
            super().end_headers()

        def log_message(self, fmt: str, *args) -> None:
            print(fmt % args)

        def do_OPTIONS(self) -> None:
            if urlparse(self.path).path.startswith("/api/"):
                self.send_response(204)
                self.send_header("Allow", "GET, POST, OPTIONS")
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
                        "intake_mode": "limited_invitation" if state.require_invite_code else "trusted_circle",
                        "invite_required": state.require_invite_code,
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

            if content_length < 1:
                self._json_response(400, {"ok": False, "errors": ["Empty request body"]})
                return
            if content_length > MAX_BODY_BYTES:
                self._json_response(413, {"ok": False, "errors": ["Request body too large"]})
                return

            try:
                raw_body = self.rfile.read(content_length).decode("utf-8")
                payload = json.loads(raw_body)
            except (UnicodeDecodeError, json.JSONDecodeError):
                self._json_response(400, {"ok": False, "errors": ["Invalid JSON payload"]})
                return

            if not isinstance(payload, dict):
                self._json_response(400, {"ok": False, "errors": ["JSON payload must be an object"]})
                return

            status_code, response = process_submission(payload, state)
            self._json_response(status_code, response)

        def _json_response(self, status_code: int, payload: dict[str, object]) -> None:
            data = json.dumps(payload).encode("utf-8")
            self.send_response(status_code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    return RegistrationPilotHandler


def synthetic_payload(invitation_code: str = "") -> dict[str, object]:
    payload: dict[str, object] = {
        "display_name": "Synthetic Participant",
        "region_or_country": "Exampleland",
        "participation_type": "Public declaration",
        "reply_contact": "private-contact@example.invalid",
        "contact_preference": "Email",
        "privacy_request": "Private follow-up first",
        "note": "Synthetic H2 intake test only.",
        "consent_ordinary_email_only": True,
    }
    if invitation_code:
        payload["invitation_code"] = invitation_code
    return payload


def self_test() -> None:
    fixed_now = datetime(2026, 8, 30, 11, 40, tzinfo=timezone.utc)

    with tempfile.TemporaryDirectory(prefix="groundmesh-human-mesh-h2-") as raw:
        temp = Path(raw)

        # H1 compatibility: direct trusted-circle mode still accepts no invite code.
        h1_state = PilotState(temp / "h1", require_invite_code=False, steward_name="Synthetic Steward")
        status, response = process_submission(synthetic_payload(), h1_state, fixed_now)
        assert status == 201 and response["ok"] is True
        assert not h1_state.invites_path.exists()

        # H2: generate codes locally. Only hashes may persist.
        h2_state = PilotState(temp / "h2", require_invite_code=True, steward_name="Synthetic Steward")
        codes = generate_invites(h2_state, count=2, expires_days=2, now=fixed_now)
        valid_code, expired_code = codes
        registry = load_invite_registry(h2_state)
        invite_text = h2_state.invites_path.read_text(encoding="utf-8")
        assert valid_code not in invite_text and expired_code not in invite_text

        # Make the second code expired without exposing plaintext.
        invites = registry["invites"]
        assert isinstance(invites, list)
        invites[1]["expires_at"] = iso_utc(fixed_now - timedelta(seconds=1))
        save_invite_registry(h2_state, registry)

        status, _ = process_submission(synthetic_payload("gmh2-invalid"), h2_state, fixed_now)
        assert status == 403

        status, _ = process_submission(synthetic_payload(expired_code), h2_state, fixed_now)
        assert status == 403

        # Malformed participant data must not consume a valid invite.
        malformed = synthetic_payload(valid_code)
        malformed["display_name"] = ""
        status, _ = process_submission(malformed, h2_state, fixed_now)
        assert status == 400

        registry = load_invite_registry(h2_state)
        valid_item, error = find_usable_invite(registry, valid_code, fixed_now)
        assert error is None and valid_item is not None
        assert int(valid_item["uses_remaining"]) == 1

        # Valid invite works once.
        status, response = process_submission(synthetic_payload(valid_code), h2_state, fixed_now)
        assert status == 201 and response["ok"] is True
        status, _ = process_submission(synthetic_payload(valid_code), h2_state, fixed_now)
        assert status == 403

        # Admission secret must not leak into participant records/logs.
        leaked = []
        for path in h2_state.private_root.rglob("*"):
            if not path.is_file():
                continue
            text = path.read_text(encoding="utf-8")
            if path == h2_state.invites_path:
                assert valid_code not in text and expired_code not in text
                continue
            if valid_code in text or expired_code in text:
                leaked.append(str(path))
        assert not leaked, f"plaintext invite leaked into: {leaked}"

        submission_files = list(h2_state.submissions_root.glob("*.json"))
        assert len(submission_files) == 1
        stored = json.loads(submission_files[0].read_text(encoding="utf-8"))
        assert "invitation_code" not in stored
        assert stored["reply_contact"] == "private-contact@example.invalid"

    print("Human Mesh H2 invite-gated intake self-test OK")


def main() -> None:
    parser = argparse.ArgumentParser(description="GroundMesh registration pilot server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument(
        "--private-root",
        type=Path,
        default=DEFAULT_PRIVATE_ROOT,
        help="Local private registration workspace (default: private/registration_pilot/)",
    )
    parser.add_argument(
        "--require-invite-code",
        action="store_true",
        help="Enable H2 limited-invitation mode. Off by default for H1 trusted-circle compatibility.",
    )
    parser.add_argument(
        "--create-invites",
        type=int,
        metavar="N",
        help="Create N local invite codes, print them once, then exit. Only hashes are stored.",
    )
    parser.add_argument("--invite-expires-days", type=int, default=14)
    parser.add_argument("--invite-uses", type=int, default=1)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    state = PilotState(args.private_root, require_invite_code=args.require_invite_code)

    if args.self_test:
        self_test()
        return

    if args.create_invites is not None:
        codes = generate_invites(
            state,
            count=args.create_invites,
            expires_days=args.invite_expires_days,
            uses=args.invite_uses,
        )
        print("GroundMesh H2 invite codes (shown once; share only with intended participants):")
        for code in codes:
            print(code)
        print(f"Stored hashed invite registry: {state.invites_path}")
        return

    handler = make_handler(state)
    server = ThreadingHTTPServer((args.host, args.port), handler)
    mode = "H2 limited invitation" if args.require_invite_code else "H1 trusted circle"
    print(f"GroundMesh registration pilot server ({mode}) running at http://{args.host}:{args.port}/register-pilot.html")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
