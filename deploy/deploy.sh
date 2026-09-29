#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REGION=${AWS_REGION:-us-east-1}
HOST=""
KEY=""
ENV_FILE="$ROOT/.local/app.env"
CONFIRM=""

usage() {
    printf 'Usage: %s --host PUBLIC_IP --key PRIVATE_KEY --confirm DEPLOY\n' "$0" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            HOST=$2
            shift 2
            ;;
        --key)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            KEY=$2
            shift 2
            ;;
        --env-file)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            ENV_FILE=$2
            shift 2
            ;;
        --confirm)
            [[ $# -ge 2 ]] || { usage; exit 2; }
            CONFIRM=$2
            shift 2
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

[[ -n "$HOST" && -n "$KEY" ]] || { usage; exit 2; }
[[ "$CONFIRM" == "DEPLOY" ]] || { printf 'Refusing deployment: pass --confirm DEPLOY after reviewing the target.\n' >&2; exit 1; }
[[ -f "$KEY" ]] || { printf 'Private key not found.\n' >&2; exit 1; }
[[ -f "$ENV_FILE" ]] || { printf 'Secret file not found.\n' >&2; exit 1; }
[[ "$(stat -c '%a' "$ENV_FILE")" == "600" ]] || { printf 'Secret file must have mode 600.\n' >&2; exit 1; }

COMMIT=$(git -C "$ROOT" rev-parse --verify --short=40 HEAD)
TMP_USER_DATA_DIR=$(mktemp -d "$ROOT/.local/.w04-user-data.XXXXXX")
TMP_USER_DATA="$TMP_USER_DATA_DIR/user-data.sh"
trap 'rm -rf "$TMP_USER_DATA_DIR"' EXIT
bash "$ROOT/deploy/make-user-data.sh" HEAD "$TMP_USER_DATA" >/dev/null
chmod 600 "$TMP_USER_DATA"

printf 'Target host: %s\nCommit: %s\nSecret destination: /etc/inspection/app.env (mode 600)\n' "$HOST" "$COMMIT"
printf 'Type DEPLOY to continue: '
read -r APPROVAL
[[ "$APPROVAL" == "DEPLOY" ]] || { printf 'Cancelled; no deployment made.\n' >&2; exit 1; }

SSH=(ssh -i "$KEY" -o StrictHostKeyChecking=accept-new -o BatchMode=yes "ec2-user@$HOST")
SCP=(scp -i "$KEY" -o StrictHostKeyChecking=accept-new)

"${SCP[@]}" "$TMP_USER_DATA" "ec2-user@$HOST:/tmp/w04-user-data.sh"
"${SSH[@]}" 'sudo bash /tmp/w04-user-data.sh'

"${SSH[@]}" 'sudo install -d -o root -g root -m 755 /etc/inspection'
"${SSH[@]}" 'sudo install -o root -g root -m 600 /dev/stdin /etc/inspection/app.env' < "$ENV_FILE"
"${SSH[@]}" 'sudo systemctl restart inspection'

HEALTH=$(curl -fsS --max-time 8 "http://$HOST/health")
python3 - "$COMMIT" "$HEALTH" <<'PY'
import json
import sys
expected, raw = sys.argv[1:]
result = json.loads(raw)
if result.get("version") != expected or result.get("auth_configured") is not True:
    raise SystemExit("health check failed: version or auth_configured mismatch")
print("Deployment verified: version and auth_configured=true")
PY
