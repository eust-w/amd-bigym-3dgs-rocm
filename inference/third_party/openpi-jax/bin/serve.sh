#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

test -d "$OPENPI_DIR/.git" || fail "run inference/third_party/openpi-jax/bin/bootstrap.sh first"
test -f "$CHECKPOINT_DIR/params/_METADATA" || fail "run inference/third_party/openpi-jax/bin/download_checkpoint.sh first"

test -x "$POLICY_PYTHON" || fail "run inference/third_party/openpi-jax/bin/bootstrap.sh first: $POLICY_PYTHON"

mkdir -p "$RUNTIME_EVIDENCE_DIR" "$AMD_PIPELINE_ROOT/data/dishwasher_unload_cutlery_long"
export ROCR_VISIBLE_DEVICES=$INFERENCE_GPU
export HIP_VISIBLE_DEVICES=$INFERENCE_GPU
export XLA_PYTHON_CLIENT_MEM_FRACTION=${XLA_PYTHON_CLIENT_MEM_FRACTION:-0.75}
export TOKENIZERS_PARALLELISM=false
export PYTHONUNBUFFERED=1
export ROCM_PATH=${ROCM_PATH:-/opt/rocm}
export LD_LIBRARY_PATH="$ROCM_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

export OPENPI_DIR
export POLICY_CHECKPOINT_REVISION=${POLICY_CHECKPOINT_REVISION:-$CHECKPOINT_REVISION}
exec "$POLICY_PYTHON" "$PROVIDER_DIR/src/server.py" \
  --action-dim 16 \
  --model-action-dim 32 \
  --action-horizon 10 \
  --camera-names high l_wrist r_wrist \
  --camera-sources observation.images.cam_high \
    observation.images.cam_left_wrist \
    observation.images.cam_right_wrist \
  --wrist-names l_wrist r_wrist \
  --data-dir "$AMD_PIPELINE_ROOT/data/dishwasher_unload_cutlery_long" \
  --checkpoint-dir "$CHECKPOINT_DIR" \
  --lora \
  --default-prompt "Unload cutlery from dishwasher to drawer task." \
  --host "$INFERENCE_HOST" \
  --port "$INFERENCE_PORT"
