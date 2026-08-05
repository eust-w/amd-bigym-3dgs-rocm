#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
"$ROOT/evaluation/bigym-3dgs/bin/bootstrap_bigym_source.sh"
exec "$ROOT/inference/third_party/openpi-jax/bin/bootstrap.sh" "$@"
