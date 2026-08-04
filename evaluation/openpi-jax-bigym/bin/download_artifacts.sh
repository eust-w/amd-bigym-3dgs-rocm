#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

HF_CLI=${HF_CLI:-$(command -v hf || true)}
if test -z "$HF_CLI" && test -x /opt/venv/bin/hf; then
  HF_CLI=/opt/venv/bin/hf
fi
test -x "$HF_CLI" || fail "Hugging Face CLI is unavailable; set HF_CLI"
mkdir -p "$CHECKPOINT_DIR" "$SHELL_DIR"

"$HF_CLI" download "$CHECKPOINT_REPOSITORY" \
  --revision "$CHECKPOINT_REVISION" \
  --local-dir "$CHECKPOINT_DIR"

"$HF_CLI" download "$SHELL_REPOSITORY" \
  --repo-type dataset \
  --revision "$SHELL_REVISION" \
  --local-dir "$SHELL_DIR"

test -f "$CHECKPOINT_DIR/params/_METADATA" \
  || fail "checkpoint params/_METADATA is missing"
test -f "$CHECKPOINT_DIR/assets/dishwasher_unload_cutlery_long/norm_stats.json" \
  || fail "checkpoint norm_stats.json is missing"
test -f "$SHELL_DIR/scene-shell-profile.json" \
  || fail "AMD scene-shell-profile.json is missing"

(cd "$SHELL_DIR" && sha256sum -c CHECKSUMS.sha256)

python3 "$EVAL_DIR/src/verify_artifacts.py" \
  --lock "$EVAL_DIR/VERSION_LOCK.json" \
  --checkpoint "$CHECKPOINT_DIR" \
  --shell "$SHELL_DIR"

printf 'ARTIFACTS_READY checkpoint=%s shell=%s\n' "$CHECKPOINT_DIR" "$SHELL_DIR"
