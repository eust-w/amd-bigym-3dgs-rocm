#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
PYTHON=${PYTHON:-python3}
OUTPUT=${OUTPUT:-"$REPO_ROOT/data/private/dl3dv-kitchen"}

"$PYTHON" "$REPO_ROOT/reconstruction/src/download_dl3dv_scene.py" \
  --output "$OUTPUT" \
  --scene-hash 951f9db189a7023708b7798e147e04048a84ce039c5761e8ecb1aa65dcb2da86 \
  --batch 3K \
  --category "screened center-clean kitchen"

printf 'Reference source verified at %s\n' "$OUTPUT"
