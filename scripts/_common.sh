#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass_count=0
fail_count=0
warn_count=0

pass() {
  pass_count=$((pass_count+1))
  printf "PASS: %s\n" "$1"
}

fail() {
  fail_count=$((fail_count+1))
  printf "FAIL: %s\n" "$1"
}

warn() {
  warn_count=$((warn_count+1))
  printf "WARN: %s\n" "$1"
}

check_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "command available: $cmd"
  else
    fail "command not found: $cmd"
  fi
}

check_file_exists() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

check_file_contains() {
  local path="$1"
  local needle="$2"
  if [[ ! -f "$path" ]]; then
    fail "missing file: $path"
    return
  fi
  if grep -Fq "$needle" "$path"; then
    pass "found in $path: $needle"
  else
    fail "missing in $path: $needle"
  fi
}

check_env_var() {
  local name="$1"
  if [[ -n "${!name:-}" ]]; then
    pass "env set: $name"
  else
    fail "env missing: $name"
  fi
}

run_check() {
  local desc="$1"
  local cmd="$2"
  if bash -c "$cmd" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

run_check_verbose() {
  local desc="$1"
  local cmd="$2"
  if bash -c "$cmd"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

check_http() {
  local desc="$1"
  local url="$2"
  if curl -fsS "$url" >/dev/null 2>&1; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

summary_and_exit() {
  printf "\nSummary: %d passed, %d failed, %d warnings\n" "$pass_count" "$fail_count" "$warn_count"
  if [[ "$fail_count" -gt 0 ]]; then
    exit 1
  fi
}
