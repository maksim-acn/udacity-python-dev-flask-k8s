#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/verify-prereqs.sh"
"$SCRIPT_DIR/verify-local.sh"
"$SCRIPT_DIR/verify-docker.sh"
"$SCRIPT_DIR/verify-cicd.sh"
"$SCRIPT_DIR/verify-eks.sh"
"$SCRIPT_DIR/verify-deployment.sh"
