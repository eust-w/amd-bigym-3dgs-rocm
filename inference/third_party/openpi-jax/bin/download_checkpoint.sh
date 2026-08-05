#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

HF_CLI=${HF_CLI:-$(command -v hf || true)}
if test -z "$HF_CLI" && test -x /opt/venv/bin/hf; then
  HF_CLI=/opt/venv/bin/hf
fi
test -x "$HF_CLI" || fail "Hugging Face CLI is unavailable; set HF_CLI"
mkdir -p "$CHECKPOINT_DIR"

"$HF_CLI" download "$CHECKPOINT_REPOSITORY" \
  --revision "$CHECKPOINT_REVISION" \
  --local-dir "$CHECKPOINT_DIR"

python3 "$PROVIDER_DIR/src/verify_checkpoint.py" \
  --lock "$PROVIDER_DIR/VERSION_LOCK.json" \
  --checkpoint "$CHECKPOINT_DIR"

printf 'OPENPI_CHECKPOINT_READY checkpoint=%s\n' "$CHECKPOINT_DIR"
