#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

IMAGE_TAG="${IMAGE_TAG:-simple-jwt-api:verify}"
CONTAINER_NAME="${CONTAINER_NAME:-simple-jwt-api-verify}"
DOCKER_PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

check_command docker
check_file_exists "$ROOT_DIR/Dockerfile"

check_file_contains "$ROOT_DIR/Dockerfile" "ENTRYPOINT [\"gunicorn\", \"-b\", \":8080\", \"main:APP\"]"
check_file_contains "$ROOT_DIR/Dockerfile" "pip install -r requirements.txt"

if grep -Fq "FROM public.ecr.aws/sam/build-python3.7:latest" "$ROOT_DIR/Dockerfile" \
  || grep -Fq "FROM python:stretch" "$ROOT_DIR/Dockerfile"; then
  pass "Dockerfile base image looks correct"
else
  fail "Dockerfile base image not recognized"
fi

if [[ -f "$ROOT_DIR/.env_file" ]]; then
  pass "env file exists: .env_file"
  check_file_contains "$ROOT_DIR/.env_file" "JWT_SECRET="
  check_file_contains "$ROOT_DIR/.env_file" "LOG_LEVEL="
else
  warn "missing .env_file (required to run container)"
fi

check_file_contains "$ROOT_DIR/.gitignore" ".env_file"

if [[ "${VERIFY_SKIP_DOCKER_BUILD:-}" == "1" ]]; then
  warn "skipping docker build (VERIFY_SKIP_DOCKER_BUILD=1)"
else
  run_check_verbose "build docker image" "cd '$ROOT_DIR' && docker build --platform '$DOCKER_PLATFORM' -t '$IMAGE_TAG' ."
fi

if [[ "${VERIFY_RUN_CONTAINER:-}" == "1" ]]; then
  if [[ ! -f "$ROOT_DIR/.env_file" ]]; then
    fail "cannot run container without .env_file"
  else
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    run_check_verbose "run container" "cd '$ROOT_DIR' && docker run --platform '$DOCKER_PLATFORM' -d --name '$CONTAINER_NAME' --env-file .env_file -p 18080:8080 '$IMAGE_TAG'"
    sleep 2
    check_http "container health endpoint" "http://127.0.0.1:18080/"
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
else
  warn "skipping container run (set VERIFY_RUN_CONTAINER=1 to enable)"
fi

summary_and_exit
