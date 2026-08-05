#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
"$ROOT/evaluation/bigym-3dgs/bin/download_shell.sh"
exec "$ROOT/inference/third_party/openpi-jax/bin/download_checkpoint.sh" "$@"
