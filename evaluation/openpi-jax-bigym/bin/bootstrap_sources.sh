#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_command git
clone_pinned "$OPENPI_REPOSITORY" "$OPENPI_COMMIT" "$OPENPI_DIR"
clone_pinned "$BIGYM_REPOSITORY" "$BIGYM_COMMIT" "$BIGYM_DIR"

mkdir -p "$AMD_EVAL_ROOT/data/dishwasher_unload_cutlery_long"
"$EVAL_DIR/bin/bootstrap_openpi_venv.sh"

printf 'SOURCES_BOOTSTRAPPED openpi=%s bigym=%s\n' \
  "$(git -C "$OPENPI_DIR" rev-parse HEAD)" \
  "$(git -C "$BIGYM_DIR" rev-parse HEAD)"
