#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_common.sh"

SERVICE_NAME="${SERVICE_NAME:-simple-jwt-api}"
NAMESPACE="${K8S_NAMESPACE:-default}"

if ! kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  fail "service not found: $SERVICE_NAME in namespace $NAMESPACE"
  summary_and_exit
fi

endpoint="$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}')"

if [[ -z "$endpoint" ]]; then
  fail "service has no external endpoint yet"
  summary_and_exit
fi

url="http://$endpoint"
check_http "service health endpoint" "$url/"

summary_and_exit
