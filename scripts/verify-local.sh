#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

PYTHON_BIN="${PYTHON_BIN:-}"
PIP_BIN="${PIP_BIN:-}"

if [[ -z "$PYTHON_BIN" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN=python3
  else
    PYTHON_BIN=python
  fi
fi

if [[ -z "$PIP_BIN" ]]; then
  if command -v pip3 >/dev/null 2>&1; then
    PIP_BIN=pip3
  else
    PIP_BIN=pip
  fi
fi

APP_URL="${APP_URL:-http://127.0.0.1:8080}"
AUTH_EMAIL="${AUTH_EMAIL:-test@test.com}"
AUTH_PASSWORD="${AUTH_PASSWORD:-test}"

check_file_exists "$ROOT_DIR/requirements.txt"
check_file_exists "$ROOT_DIR/main.py"
check_file_exists "$ROOT_DIR/test_main.py"

check_env_var JWT_SECRET
check_env_var LOG_LEVEL

if [[ "${VERIFY_SKIP_INSTALL:-}" == "1" ]]; then
  warn "skipping dependency install (VERIFY_SKIP_INSTALL=1)"
else
  run_check_verbose "install dependencies" "cd '$ROOT_DIR' && $PIP_BIN install -r requirements.txt"
fi

if [[ "${VERIFY_SKIP_TESTS:-}" == "1" ]]; then
  warn "skipping tests (VERIFY_SKIP_TESTS=1)"
else
  run_check_verbose "run unit tests" "cd '$ROOT_DIR' && $PYTHON_BIN -m pytest test_main.py"
fi

if [[ "${VERIFY_REQUIRE_APP:-}" == "1" ]]; then
  check_http "health endpoint" "$APP_URL/"
else
  if curl -fsS "$APP_URL/" >/dev/null 2>&1; then
    pass "health endpoint"
  else
    warn "app not reachable at $APP_URL (start the app to verify endpoints)"
  fi
fi

if curl -fsS "$APP_URL/" >/dev/null 2>&1; then
  token="$(curl -fsS -X POST "$APP_URL/auth" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$AUTH_EMAIL\",\"password\":\"$AUTH_PASSWORD\"}" \
    | $PYTHON_BIN - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('token', ''))
except Exception:
    print('')
PY
  )"

  if [[ -n "$token" ]]; then
    pass "auth endpoint returns token"
    if curl -fsS "$APP_URL/contents" -H "Authorization: Bearer $token" >/dev/null 2>&1; then
      pass "contents endpoint returns payload"
    else
      fail "contents endpoint failed"
    fi
  else
    fail "auth endpoint failed"
  fi
fi

summary_and_exit
