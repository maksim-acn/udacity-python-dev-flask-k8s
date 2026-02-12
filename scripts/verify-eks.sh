#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

CLUSTER_NAME="${CLUSTER_NAME:-simple-jwt-api}"
REGION="${AWS_REGION:-eu-central-1}"

check_command aws
check_command eksctl
check_command kubectl

if [[ "${VERIFY_REQUIRE_AWS:-}" == "1" ]]; then
  run_check "AWS caller identity" "aws sts get-caller-identity"
else
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    warn "AWS not configured (set VERIFY_REQUIRE_AWS=1 to enforce)"
    summary_and_exit
  fi
fi

cluster_exists=0
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  pass "cluster exists"
  cluster_exists=1
else
  if [[ "${VERIFY_REQUIRE_CLUSTER:-}" == "1" ]]; then
    fail "cluster exists"
  else
    warn "cluster not found yet (set VERIFY_REQUIRE_CLUSTER=1 to enforce): $CLUSTER_NAME ($REGION)"
  fi
fi

if [[ "$cluster_exists" == "1" ]]; then
  run_check "kubeconfig updated" "aws eks update-kubeconfig --name '$CLUSTER_NAME' --region '$REGION'"
  run_check_verbose "kubectl get nodes" "kubectl get nodes"
fi

summary_and_exit
