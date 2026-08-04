#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

test -x "$BIGYM_PYTHON" || fail "BiGym ROCm Python is missing: $BIGYM_PYTHON"
test -d "$BIGYM_DIR/.git" || fail "run bootstrap_sources.sh first"
test -f "$SHELL_DIR/scene-shell-profile.json" || fail "run download_artifacts.sh first"

MODE=${1:-smoke}
case "$MODE" in
  smoke) N_EPISODES=${N_EPISODES:-3} ;;
  formal) N_EPISODES=${N_EPISODES:-32} ;;
  *) fail "mode must be smoke or formal" ;;
esac

OUTPUT_DIR="$RESULTS_ROOT/$MODE"
mkdir -p "$OUTPUT_DIR" "$RUNTIME_EVIDENCE_DIR"

curl --fail --silent "$POLICY_BASE_URL/health" > "$RUNTIME_EVIDENCE_DIR/policy-health.json"
export ROCR_VISIBLE_DEVICES=$SIM_GPU
export HIP_VISIBLE_DEVICES=$SIM_GPU
export MUJOCO_GL=${MUJOCO_GL:-egl}
export PYOPENGL_PLATFORM=${PYOPENGL_PLATFORM:-egl}
export PYTHONPATH="$BIGYM_DIR${PYTHONPATH:+:$PYTHONPATH}"
export TORCH_EXTENSIONS_DIR=${TORCH_EXTENSIONS_DIR:-$AMD_EVAL_ROOT/cache/torch-extensions-gsplat}

"$BIGYM_PYTHON" "$EVAL_DIR/src/eval_bigym_3dgs.py" \
  --bigym-root "$BIGYM_DIR" \
  --task DishwasherUnloadCutleryLong \
  --base-url "$POLICY_BASE_URL" \
  --visual-shell-profile "$SHELL_DIR/scene-shell-profile.json" \
  --output-dir "$OUTPUT_DIR" \
  --n-episodes "$N_EPISODES" \
  --seed0 0 \
  --tag "amd-jax-$MODE"

python3 "$EVAL_DIR/src/summarize_results.py" \
  --results "$OUTPUT_DIR/dishwasher_unload_cutlery_long/results.json" \
  --output "$OUTPUT_DIR/evaluation-summary.json" \
  --expected-episodes "$N_EPISODES"

rocm-smi --showmeminfo vram --showuse > "$RUNTIME_EVIDENCE_DIR/rocm-smi-after-$MODE.txt"
printf 'BIGYM_EVAL_COMPLETE mode=%s episodes=%s output=%s\n' "$MODE" "$N_EPISODES" "$OUTPUT_DIR"
