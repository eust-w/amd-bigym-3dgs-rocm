#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
exec "$ROOT/inference/third_party/openpi-jax/bin/serve.sh" "$@"
