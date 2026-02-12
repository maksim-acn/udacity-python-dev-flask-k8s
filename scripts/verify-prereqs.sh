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

check_command docker
check_command "$PYTHON_BIN"
check_command "$PIP_BIN"
check_command aws
check_command eksctl
check_command kubectl

run_check_verbose "docker version" "docker --version"
run_check_verbose "python version" "$PYTHON_BIN --version"
run_check_verbose "pip version" "$PIP_BIN --version"

run_check "python version is 3.7-3.9" "$PYTHON_BIN - <<'PY'
import sys
v = sys.version_info
ok = (v.major == 3 and v.minor in (7, 8, 9))
raise SystemExit(0 if ok else 1)
PY"

run_check "pip version is >= 19" "$PYTHON_BIN - <<'PY'
import re, subprocess, sys
out = subprocess.check_output([sys.executable, '-m', 'pip', '--version']).decode()
match = re.search(r'(\d+)\.(\d+)', out)
ok = False
if match:
    major, minor = int(match.group(1)), int(match.group(2))
    ok = (major > 19) or (major == 19 and minor >= 0)
raise SystemExit(0 if ok else 1)
PY"

summary_and_exit
