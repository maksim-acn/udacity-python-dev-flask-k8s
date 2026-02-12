#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

AWS_REGION="${AWS_REGION:-eu-central-1}"

check_file_exists "$ROOT_DIR/buildspec.yml"
check_file_exists "$ROOT_DIR/ci-cd-codepipeline.cfn.yml"

check_file_contains "$ROOT_DIR/buildspec.yml" "parameter-store"
check_file_contains "$ROOT_DIR/buildspec.yml" "JWT_SECRET"
check_file_contains "$ROOT_DIR/buildspec.yml" "python -m pytest test_main.py"
check_file_contains "$ROOT_DIR/buildspec.yml" "pip3 install -r requirements.txt"

check_file_contains "$ROOT_DIR/ci-cd-codepipeline.cfn.yml" "EksClusterName"
check_file_contains "$ROOT_DIR/ci-cd-codepipeline.cfn.yml" "GitSourceRepo"
check_file_contains "$ROOT_DIR/ci-cd-codepipeline.cfn.yml" "GitHubUser"
check_file_contains "$ROOT_DIR/ci-cd-codepipeline.cfn.yml" "KubectlRoleName"

if [[ "${VERIFY_REQUIRE_AWS:-}" == "1" ]]; then
  run_check "AWS caller identity" "aws sts get-caller-identity"
  run_check "JWT_SECRET exists in parameter store" "aws ssm get-parameter --name JWT_SECRET --region '$AWS_REGION'"
else
  if aws sts get-caller-identity >/dev/null 2>&1; then
    pass "AWS caller identity"
    if aws ssm get-parameter --name JWT_SECRET --region "$AWS_REGION" >/dev/null 2>&1; then
      pass "JWT_SECRET exists in parameter store"
    else
      warn "JWT_SECRET not found in parameter store"
    fi
  else
    warn "AWS not configured (set VERIFY_REQUIRE_AWS=1 to enforce)"
  fi
fi

summary_and_exit
