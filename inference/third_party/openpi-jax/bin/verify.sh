#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

for script in "$PROVIDER_DIR"/bin/*.sh; do
  bash -n "$script"
done
python3 -m compileall -q "$PROVIDER_DIR/src" "$PROVIDER_DIR/tests"
python3 -m unittest discover -s "$PROVIDER_DIR/tests" -v
printf 'OPENPI_JAX_PROVIDER_CONTRACT_OK\n'
