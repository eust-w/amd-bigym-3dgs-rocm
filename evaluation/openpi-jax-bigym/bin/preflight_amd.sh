#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
export INFERENCE_PROVIDER=${INFERENCE_PROVIDER:-openpi-jax}
exec "$ROOT/evaluation/bigym-3dgs/bin/preflight_amd.sh" "$@"
