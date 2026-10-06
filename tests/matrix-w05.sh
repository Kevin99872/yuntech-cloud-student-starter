#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HOST=${1:?Usage: tests/matrix-w05.sh PUBLIC_IP PRIVATE_KEY}
KEY=${2:?Usage: tests/matrix-w05.sh PUBLIC_IP PRIVATE_KEY}
ENV_FILE="$ROOT/.local/app.env"
FIXTURE="$ROOT/tests/fixtures/event-valid.json"

[[ -f "$ENV_FILE" ]] || { printf 'Secret file not found.\n' >&2; exit 1; }
[[ "$(stat -c '%a' "$ENV_FILE")" == "600" ]] || { printf 'Secret file must have mode 600.\n' >&2; exit 1; }
[[ -f "$KEY" ]] || { printf 'Private key not found.\n' >&2; exit 1; }

set -a
. "$ENV_FILE"
set +a
[[ -n "${REPORTER_TOKEN:-}" && -n "${OPERATOR_TOKEN:-}" ]] || { printf 'Required tokens are missing.\n' >&2; exit 1; }

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
EVENT_FILE="$TEMP_DIR/event.json"
RESPONSE_FILE="$TEMP_DIR/response.json"

python3 - "$FIXTURE" "$EVENT_FILE" <<'PY'
import json
import sys
import time

source, destination = sys.argv[1:]
event = json.loads(open(source, encoding="utf-8").read())
event["event_id"] = "w05-matrix-" + str(time.time_ns())
with open(destination, "w", encoding="utf-8") as stream:
    json.dump(event, stream)
PY

BASE_URL="http://$HOST"
SSH=(ssh -i "$KEY" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "ec2-user@$HOST")

printf 'version='
curl --silent --show-error --fail --max-time 8 "$BASE_URL/health"
printf '\n'
printf 'db_configured=true is required above.\n'

run_case() {
    local number=$1 expected=$2 method=$3 path=$4 token=$5 body_file=$6
    local status
    local -a args=(--silent --show-error --max-time 8 -X "$method" -o "$RESPONSE_FILE" -w '%{http_code}')
    [[ -n "$token" ]] && args+=( -H "Authorization: Bearer $token" )
    [[ -n "$body_file" ]] && args+=( -H 'Content-Type: application/json' --data-binary "@$body_file" )
    status=$(curl "${args[@]}" "$BASE_URL$path")
    printf '#%s status=%s body=' "$number" "$status"
    tr '\n' ' ' < "$RESPONSE_FILE"
    printf '\n'
    [[ "$status" == "$expected" ]] || {
        printf 'Expected #%s HTTP %s, got %s.\n' "$number" "$expected" "$status" >&2
        exit 1
    }
}

EVENT_ID=$(python3 -c 'import json; print(json.load(open("'"$EVENT_FILE"'"))["event_id"])')
run_case 1 201 POST /events "$REPORTER_TOKEN" "$EVENT_FILE"
run_case 2 200 POST /events "$REPORTER_TOKEN" "$EVENT_FILE"
python3 - "$EVENT_FILE" "$TEMP_DIR/conflict.json" <<'PY'
import json
import sys

event = json.load(open(sys.argv[1], encoding="utf-8"))
event["note"] = "different note"
json.dump(event, open(sys.argv[2], "w", encoding="utf-8"))
PY
run_case 3 409 POST /events "$REPORTER_TOKEN" "$TEMP_DIR/conflict.json"

"${SSH[@]}" 'sudo systemctl restart inspection'
run_case 4 200 GET "/events/$EVENT_ID" "$OPERATOR_TOKEN" ''

printf '#5 psql count='
"${SSH[@]}" 'sudo bash -c '\''set -a; . /etc/inspection/app.env; set +a
  PGPASSWORD="$DB_PASSWORD" psql "host=$DB_HOST dbname=$DB_NAME user=$DB_USER sslmode=verify-full sslrootcert=/etc/inspection/rds-ca.pem" \
    -v event_id="'"$EVENT_ID"'" -tA'\'' ' <<'SQL'
SELECT count(*) FROM events WHERE event_id = :'event_id';
SQL
