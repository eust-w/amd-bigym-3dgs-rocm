#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

test -d "$OPENPI_DIR/.git" || fail "run bootstrap_sources.sh first"
test -f "$CHECKPOINT_DIR/params/_METADATA" || fail "run download_artifacts.sh first"

test -x "$POLICY_PYTHON" || fail "run bootstrap_sources.sh first: $POLICY_PYTHON"

mkdir -p "$RUNTIME_EVIDENCE_DIR" "$AMD_EVAL_ROOT/data/dishwasher_unload_cutlery_long"
export ROCR_VISIBLE_DEVICES=$POLICY_GPU
export HIP_VISIBLE_DEVICES=$POLICY_GPU
export XLA_PYTHON_CLIENT_MEM_FRACTION=${XLA_PYTHON_CLIENT_MEM_FRACTION:-0.75}
export TOKENIZERS_PARALLELISM=false
export ROCM_PATH=${ROCM_PATH:-/opt/rocm}
export LD_LIBRARY_PATH="$ROCM_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

exec "$POLICY_PYTHON" "$OPENPI_DIR/inference_server_bigym.py" \
  --action-dim 16 \
  --model-action-dim 32 \
  --action-horizon 10 \
  --camera-names high l_wrist r_wrist \
  --camera-sources observation.images.cam_high \
    observation.images.cam_left_wrist \
    observation.images.cam_right_wrist \
  --wrist-names l_wrist r_wrist \
  --data-dir "$AMD_EVAL_ROOT/data/dishwasher_unload_cutlery_long" \
  --checkpoint-dir "$CHECKPOINT_DIR" \
  --lora \
  --default-prompt "Unload cutlery from dishwasher to drawer task." \
  --host "$POLICY_HOST" \
  --port "$POLICY_PORT"
