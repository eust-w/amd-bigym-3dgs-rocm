#!/usr/bin/env bash
set -euo pipefail

EVAL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO_ROOT=$(cd "$EVAL_DIR/../.." && pwd)
AMD_EVAL_ROOT=${AMD_EVAL_ROOT:-/workspace/amd-bigym-openpi-eval}
OPENPI_DIR=${OPENPI_DIR:-$AMD_EVAL_ROOT/src/openpi_lerobot_plus}
BIGYM_DIR=${BIGYM_DIR:-$AMD_EVAL_ROOT/src/bigym_plus}
CHECKPOINT_DIR=${CHECKPOINT_DIR:-$AMD_EVAL_ROOT/artifacts/pi05_ckpts}
SHELL_DIR=${SHELL_DIR:-$AMD_EVAL_ROOT/artifacts/amd-kitchen-shell}
RESULTS_ROOT=${RESULTS_ROOT:-$AMD_EVAL_ROOT/results}
RUNTIME_EVIDENCE_DIR=${RUNTIME_EVIDENCE_DIR:-$RESULTS_ROOT/runtime}
POLICY_ENV=${POLICY_ENV:-openpi}
POLICY_VENV=${POLICY_VENV:-$AMD_EVAL_ROOT/openpi-venv}
POLICY_PYTHON=${POLICY_PYTHON:-$POLICY_VENV/bin/python}
BIGYM_PYTHON=${BIGYM_PYTHON:-${VENV:-$AMD_EVAL_ROOT/bigym-venv}/bin/python}
POLICY_PORT=${POLICY_PORT:-7891}
POLICY_HOST=${POLICY_HOST:-127.0.0.1}
POLICY_BASE_URL=${POLICY_BASE_URL:-http://$POLICY_HOST:$POLICY_PORT}
POLICY_GPU=${POLICY_GPU:-0}
SIM_GPU=${SIM_GPU:-$POLICY_GPU}

OPENPI_REPOSITORY=https://github.com/WuChao-2024/openpi_lerobot_plus.git
OPENPI_COMMIT=9a98f3276fb6b95474ae07ff184ebd5f31686548
BIGYM_REPOSITORY=https://github.com/WuChao-2024/bigym_plus.git
BIGYM_COMMIT=d12937686833467b5013ac47a834cf4b6f5a9d53
CHECKPOINT_REPOSITORY=WuChao-Cauchy/pi05_ckpts
CHECKPOINT_REVISION=b20a8efaacc6c8e607f2ccb11f47bb2623f5c947
SHELL_REPOSITORY=eustance/amd-bigym-3dgs-kitchen-shell
SHELL_REVISION=amd-rocm-w7900d-20260804

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
