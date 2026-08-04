#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

mkdir -p "$RUNTIME_EVIDENCE_DIR"
python3 "$EVAL_DIR/src/probe_policy.py" \
  --base-url "$POLICY_BASE_URL" \
  --output "$RUNTIME_EVIDENCE_DIR/policy-contract-probe.json"
