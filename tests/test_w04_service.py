"""Offline W4 event API contract checks using the committed fixtures."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("w04_service", ROOT / "app/service.py")
service = importlib.util.module_from_spec(spec)
spec.loader.exec_module(service)


class ServiceContract(unittest.TestCase):
    def setUp(self):
        self.previous = {key: os.environ.get(key) for key in ("REPORTER_TOKEN", "OPERATOR_TOKEN")}
        os.environ["REPORTER_TOKEN"] = "reporter-test-token"
        os.environ["OPERATOR_TOKEN"] = "operator-test-token"
        self.tempdir = tempfile.TemporaryDirectory()
        version = Path(self.tempdir.name) / "version"
        version.write_text("a" * 40)
        self.server = service.make_server(version, port=0)
        self.worker = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.worker.start()
        self.base = "http://127.0.0.1:" + str(self.server.server_port)

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.worker.join(timeout=2)
        self.tempdir.cleanup()
        for key, value in self.previous.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    def request(self, method, path, body=None, token=None):
        data = None if body is None else json.dumps(body).encode()
        headers = {"Content-Type": "application/json"} if data is not None else {}
        if token:
            headers["Authorization"] = "Bearer " + token
        request = urllib.request.Request(self.base + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, json.load(response)
        except urllib.error.HTTPError as error:
            return error.code, json.load(error)

    def fixture(self, name):
        return json.loads((ROOT / "tests/fixtures" / name).read_text())

    def test_health_and_fixture_validation(self):
        status, health = self.request("GET", "/health")
        self.assertEqual(status, 200)
        self.assertTrue(health["auth_configured"])

        valid = self.fixture("event-valid.json")
        status, created = self.request("POST", "/events", valid, "reporter-test-token")
        self.assertEqual(status, 201)
        self.assertIn("received_at", created)

        status, error = self.request("POST", "/events", self.fixture("event-no-timezone.json"), "reporter-test-token")
        self.assertEqual(status, 400)
        self.assertEqual(error["field"], "observed_at")

        status, error = self.request("POST", "/events", self.fixture("event-extra-field.json"), "reporter-test-token")
        self.assertEqual(status, 400)
        self.assertEqual(error["field"], "severity")

        status, error = self.request("POST", "/events", valid, "reporter-test-token")
        self.assertEqual(status, 409)
        self.assertEqual(error["field"], "event_id")

        status, result = self.request("GET", "/events", token="operator-test-token")
        self.assertEqual(status, 200)
        self.assertEqual(result["events"][0]["event_id"], valid["event_id"])

    def test_authentication_and_authorization(self):
        valid = self.fixture("event-valid.json")
        status, _ = self.request("POST", "/events", valid)
        self.assertEqual(status, 401)
        status, _ = self.request("POST", "/events", valid, "operator-test-token")
        self.assertEqual(status, 403)
        status, _ = self.request("GET", "/events", token="reporter-test-token")
        self.assertEqual(status, 403)
