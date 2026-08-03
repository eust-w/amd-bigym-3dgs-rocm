#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
DATASET_DIR=${DATASET_DIR:?set DATASET_DIR to a prepared COLMAP dataset}
RUN_ROOT=${RUN_ROOT:-/workspace/persistent/rocm3dgs-results}
RUN_ID=${RUN_ID:-gfx1100-$(date -u +%Y%m%dT%H%M%SZ)}
OUTPUT_DIR="$RUN_ROOT/$RUN_ID"

if [[ -e "$OUTPUT_DIR" ]]; then
  printf 'Refusing to reuse output path: %s\n' "$OUTPUT_DIR" >&2
  exit 1
fi
mkdir -p "$OUTPUT_DIR"

nohup env \
  ROCM_ARCH=gfx1100 \
  TRAIN_STEPS="${TRAIN_STEPS:-30000}" \
  SAVE_EVERY="${SAVE_EVERY:-5000}" \
  HIP_VISIBLE_DEVICES="${HIP_VISIBLE_DEVICES:-0}" \
  OPENSPLAT_BIN="${OPENSPLAT_BIN:-/root/OpenSplat/build/opensplat}" \
  ROCM_VENV="${ROCM_VENV:-/root/opensplat-env}" \
  bash "$REPO_ROOT/reconstruction/bin/reconstruct_rocm_gfx1100.sh" \
    "$DATASET_DIR" "$OUTPUT_DIR" \
  >"$OUTPUT_DIR/launcher.log" 2>&1 &

PID=$!
printf '%s\n' "$PID" >"$OUTPUT_DIR/launcher.pid"
printf 'Started gfx1100 reconstruction: pid=%s output=%s\n' "$PID" "$OUTPUT_DIR"
