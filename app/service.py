#!/usr/bin/env python3
"""In-memory W4 inspection event service."""
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import re
from urllib.parse import unquote


EVENT_FIELDS = {"event_id", "device_id", "observed_at", "type", "note"}
IDENTIFIER = re.compile(r"^[A-Za-z0-9_-]+$")
EVENT_TYPES = {"status", "anomaly", "test"}


def load_tokens():
    return os.environ.get("REPORTER_TOKEN", ""), os.environ.get("OPERATOR_TOKEN", "")


def validate_event(event):
    if not isinstance(event, dict):
        return "body must be a JSON object", "body"
    extra = set(event) - EVENT_FIELDS
    if extra:
        return "unexpected field", sorted(extra)[0]
    for field in ("event_id", "device_id", "observed_at", "type"):
        if field not in event:
            return "missing field", field
    if not isinstance(event["event_id"], str) or not 1 <= len(event["event_id"]) <= 64 or not IDENTIFIER.fullmatch(event["event_id"]):
        return "invalid value", "event_id"
    if not isinstance(event["device_id"], str) or not 1 <= len(event["device_id"]) <= 32 or not IDENTIFIER.fullmatch(event["device_id"]):
        return "invalid value", "device_id"
    if not isinstance(event["observed_at"], str):
        return "invalid value", "observed_at"
    try:
        observed_at = datetime.fromisoformat(event["observed_at"].replace("Z", "+00:00"))
    except ValueError:
        return "invalid value", "observed_at"
    if observed_at.tzinfo is None or observed_at.utcoffset() is None:
        return "timezone required", "observed_at"
    if event["type"] not in EVENT_TYPES:
        return "invalid value", "type"
    if "note" in event and (not isinstance(event["note"], str) or len(event["note"]) > 200):
        return "invalid value", "note"
    return None


def make_server(version_file, port=8080):
    version = Path(version_file).read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9a-f]{40}", version):
        raise ValueError("version must contain the deployed 40-character Git commit SHA")
    started = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    events = {}

    class Handler(BaseHTTPRequestHandler):
        def setup(self):
            super().setup()
            self.connection.settimeout(5)

        def send_json(self, status, body):
            data = json.dumps(body).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def role(self):
            reporter, operator = load_tokens()
            if not reporter and not operator:
                return None, False
            authorization = self.headers.get("Authorization", "")
            if not authorization.startswith("Bearer "):
                return None, True
            token = authorization[7:]
            if token and token == reporter:
                return "reporter", True
            if token and token == operator:
                return "operator", True
            return None, True

        def require_role(self, expected):
            role, configured = self.role()
            if not configured or role is None:
                self.send_json(401, {"error": "unauthorized"})
                return False
            if role != expected:
                self.send_json(403, {"error": "forbidden"})
                return False
            return True

        def do_GET(self):
            if self.path == "/health":
                reporter, operator = load_tokens()
                self.send_json(200, {"status": "ok", "service": "inspection", "version": version,
                                     "started_at": started, "auth_configured": bool(reporter and operator)})
                return
            if self.path == "/":
                self.send_page()
                return
            if self.path == "/events":
                if self.require_role("operator"):
                    self.send_json(200, {"events": list(events.values())[-50:]})
                return
            prefix = "/events/"
            if self.path.startswith(prefix):
                if self.require_role("operator"):
                    event_id = unquote(self.path[len(prefix):])
                    event = events.get(event_id)
                    if event is None:
                        self.send_json(404, {"error": "not_found"})
                    else:
                        self.send_json(200, event)
                return
            self.send_json(404, {"error": "not_found"})

        def do_POST(self):
            if self.path != "/events":
                self.send_json(404, {"error": "not_found"})
                return
            if not self.require_role("reporter"):
                return
            content_type = self.headers.get("Content-Type", "").split(";", 1)[0].strip().lower()
            try:
                content_length = int(self.headers.get("Content-Length", "-1"))
            except ValueError:
                content_length = -1
            if content_type != "application/json" or content_length < 0 or content_length > 4096:
                self.send_json(400, {"error": "invalid_request", "field": "body"})
                return
            try:
                event = json.loads(self.rfile.read(content_length))
            except (json.JSONDecodeError, UnicodeDecodeError):
                self.send_json(400, {"error": "invalid_json", "field": "body"})
                return
            error = validate_event(event)
            if error:
                reason, field = error
                self.send_json(400, {"error": reason, "field": field})
                return
            event_id = event["event_id"]
            if event_id in events:
                self.send_json(409, {"error": "duplicate", "field": "event_id"})
                return
            stored = dict(event)
            stored["received_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
            events[event_id] = stored
            self.send_json(201, stored)

        def send_page(self):
            page = """<!doctype html><meta charset=\"utf-8\"><title>Inspection events</title>
<h1>Inspection events</h1><label>Operator token <input id=\"token\" type=\"password\"></label>
<button id=\"load\" type=\"button\">Load events</button><ul id=\"events\"></ul>
<script>
const token = document.getElementById('token');
const list = document.getElementById('events');
document.getElementById('load').addEventListener('click', async () => {
  const response = await fetch('/events', {headers: {Authorization: 'Bearer ' + token.value}});
  const result = await response.json();
  list.replaceChildren();
  (result.events || []).forEach(event => {
    const item = document.createElement('li');
    item.textContent = JSON.stringify(event);
    list.appendChild(item);
  });
});
</script>"""
            data = page.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, fmt, *args):
            pass  # Never log request paths, bodies, headers or query strings.

    return ThreadingHTTPServer(("127.0.0.1", port), Handler)


if __name__ == "__main__":
    make_server(Path(__file__).with_name("version")).serve_forever()
