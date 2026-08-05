#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
exec "$ROOT/evaluation/bigym-3dgs/bin/bootstrap_bigym_runtime.sh" "$@"
