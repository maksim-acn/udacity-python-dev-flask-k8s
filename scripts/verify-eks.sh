#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

CLUSTER_NAME="${CLUSTER_NAME:-simple-jwt-api}"
REGION="${AWS_REGION:-eu-central-1}"

if [[ "${VERIFY_REQUIRE_AWS:-}" == "1" ]]; then
  run_check "AWS caller identity" "aws sts get-caller-identity"
else
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    warn "AWS not configured (set VERIFY_REQUIRE_AWS=1 to enforce)"
    summary_and_exit
  fi
fi

run_check "cluster exists" "aws eks describe-cluster --name '$CLUSTER_NAME' --region '$REGION'"
run_check_verbose "kubectl get nodes" "kubectl get nodes"

summary_and_exit
