#!/usr/bin/env bash
set -euo pipefail

PROVIDER_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO_ROOT=$(cd "$PROVIDER_DIR/../../.." && pwd)
AMD_PIPELINE_ROOT=${AMD_PIPELINE_ROOT:-${AMD_EVAL_ROOT:-/workspace/amd-bigym-3dgs-rocm}}
OPENPI_DIR=${OPENPI_DIR:-$AMD_PIPELINE_ROOT/src/openpi_lerobot_plus}
CHECKPOINT_DIR=${CHECKPOINT_DIR:-$AMD_PIPELINE_ROOT/artifacts/pi05_ckpts}
RESULTS_ROOT=${RESULTS_ROOT:-$AMD_PIPELINE_ROOT/results}
RUNTIME_EVIDENCE_DIR=${RUNTIME_EVIDENCE_DIR:-$RESULTS_ROOT/runtime}
POLICY_VENV=${POLICY_VENV:-$AMD_PIPELINE_ROOT/openpi-venv}
POLICY_PYTHON=${POLICY_PYTHON:-$POLICY_VENV/bin/python}
INFERENCE_PORT=${INFERENCE_PORT:-${POLICY_PORT:-7891}}
INFERENCE_HOST=${INFERENCE_HOST:-${POLICY_HOST:-127.0.0.1}}
INFERENCE_GPU=${INFERENCE_GPU:-${POLICY_GPU:-0}}

OPENPI_REPOSITORY=https://github.com/WuChao-2024/openpi_lerobot_plus.git
OPENPI_COMMIT=9a98f3276fb6b95474ae07ff184ebd5f31686548
CHECKPOINT_REPOSITORY=WuChao-Cauchy/pi05_ckpts
CHECKPOINT_REVISION=b20a8efaacc6c8e607f2ccb11f47bb2623f5c947

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

require_command() {
  command -v "$1" >/dev/null || fail "required command is unavailable: $1"
}

clone_pinned() {
  local repository=$1
  local commit=$2
  local destination=$3
  if test ! -d "$destination/.git"; then
    mkdir -p "$(dirname "$destination")"
    git clone --filter=blob:none "$repository" "$destination"
  fi
  test -z "$(git -C "$destination" status --porcelain)" \
    || fail "refusing to change dirty checkout: $destination"
  git -C "$destination" fetch origin "$commit"
  git -C "$destination" checkout --detach "$commit"
  git -C "$destination" submodule update --init --recursive
  test "$(git -C "$destination" rev-parse HEAD)" = "$commit" \
    || fail "commit lock failed for $destination"
}
