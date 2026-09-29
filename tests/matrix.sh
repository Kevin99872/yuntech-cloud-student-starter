#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HOST=${1:?Usage: tests/matrix.sh PUBLIC_IP}
BASE_URL="http://$HOST"
ENV_FILE="$ROOT/.local/app.env"
FIXTURES="$ROOT/tests/fixtures"

[[ -f "$ENV_FILE" ]] || { printf 'Secret file not found.\n' >&2; exit 1; }
[[ "$(stat -c '%a' "$ENV_FILE")" == "600" ]] || { printf 'Secret file must have mode 600.\n' >&2; exit 1; }
# The tokens are inherited by curl, but are never printed.
source "$ENV_FILE"
[[ -n "${REPORTER_TOKEN:-}" && -n "${OPERATOR_TOKEN:-}" ]] || { printf 'Required tokens are missing.\n' >&2; exit 1; }

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
VALID_EVENT="$TEMP_DIR/valid.json"
NO_TIMEZONE="$FIXTURES/event-no-timezone.json"

python3 - "$FIXTURES/event-valid.json" "$VALID_EVENT" <<'PY'
import json
import sys
import time

source, destination = sys.argv[1:]
event = json.loads(open(source, encoding="utf-8").read())
event["event_id"] = "g05-w4-matrix-" + str(time.time_ns())
with open(destination, "w", encoding="utf-8") as stream:
    json.dump(event, stream)
PY

run_case() {
    local number=$1 expected=$2 method=$3 path=$4 token=$5 body_file=$6
    local response_file="$TEMP_DIR/response-$number.json"
    local status
    local -a curl_args=(--silent --show-error --max-time 8 -X "$method" -o "$response_file" -w '%{http_code}')
    if [[ -n "$token" ]]; then
        curl_args+=( -H "Authorization: Bearer $token" )
    fi
    if [[ -n "$body_file" ]]; then
        curl_args+=( -H 'Content-Type: application/json' --data-binary "@$body_file" )
    fi
    status=$(curl "${curl_args[@]}" "$BASE_URL$path")
    printf '#%s status=%s body=' "$number" "$status"
    sed ':a;N;$!ba;s/[[:space:]]\+/ /g' "$response_file"
    printf '\n'
    [[ "$status" == "$expected" ]] || {
        printf 'Expected #%s HTTP %s, got %s.\n' "$number" "$expected" "$status" >&2
        return 1
    }
}

printf 'version='
curl --silent --show-error --fail --max-time 8 "$BASE_URL/health"
printf '\n'
run_case 1 201 POST /events "$REPORTER_TOKEN" "$VALID_EVENT"
run_case 2 401 POST /events '' "$VALID_EVENT"
run_case 3 403 POST /events "$OPERATOR_TOKEN" "$VALID_EVENT"
run_case 4 400 POST /events "$REPORTER_TOKEN" "$NO_TIMEZONE"
run_case 5 409 POST /events "$REPORTER_TOKEN" "$VALID_EVENT"
run_case 6 403 GET /events "$REPORTER_TOKEN" ''
run_case 7 200 GET /events "$OPERATOR_TOKEN" ''

printf 'Matrix: 7/7 passed\n'