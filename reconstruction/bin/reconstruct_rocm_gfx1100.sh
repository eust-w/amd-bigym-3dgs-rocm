#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'usage: %s DATASET_DIR OUTPUT_DIR\n' "$0" >&2
  exit 2
fi

DATASET_DIR=$1
OUTPUT_DIR=$2
STEPS=${TRAIN_STEPS:-${STEPS:-30000}}
SAVE_INTERVAL=${SAVE_EVERY:-5000}
GPU_ID=${HIP_VISIBLE_DEVICES:-0}
OPENSPLAT_BIN=${OPENSPLAT_BIN:-/root/OpenSplat/build/opensplat}
ROCM_VENV=${ROCM_VENV:-/root/opensplat-env}
ROCM_ARCH=${ROCM_ARCH:-gfx1100}
SITE_PACKAGES=${ROCM_SITE_PACKAGES:-$ROCM_VENV/lib/python3.12/site-packages}

if [[ "$ROCM_ARCH" != gfx1100 ]]; then
  printf 'This runner is pinned to gfx1100, got %s\n' "$ROCM_ARCH" >&2
  exit 2
fi
if ! [[ "$STEPS" =~ ^[1-9][0-9]*$ && "$SAVE_INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
  printf 'TRAIN_STEPS and SAVE_EVERY must be positive integers.\n' >&2
  exit 2
fi
for path in \
  "$DATASET_DIR/images" \
  "$DATASET_DIR/sparse/0/cameras.bin" \
  "$DATASET_DIR/sparse/0/images.bin" \
  "$DATASET_DIR/sparse/0/points3D.bin"; do
  if [[ ! -e "$path" ]]; then
    printf 'COLMAP input is incomplete; missing %s\n' "$path" >&2
    exit 1
  fi
done
if [[ ! -x "$OPENSPLAT_BIN" ]]; then
  printf 'OpenSplat executable is missing: %s\n' "$OPENSPLAT_BIN" >&2
  exit 1
fi
if [[ ! -x "$ROCM_VENV/bin/python" ]]; then
  printf 'ROCm Python environment is missing: %s\n' "$ROCM_VENV" >&2
  exit 1
fi
if ! command -v rocminfo >/dev/null || ! rocminfo 2>/dev/null | grep -q 'gfx1100'; then
  printf 'No gfx1100 agent is visible to ROCm.\n' >&2
  exit 1
fi
if [[ -e "$OUTPUT_DIR" ]] && [[ -n $(
  find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 \
    ! -name launcher.log ! -name launcher.pid -print -quit
) ]]; then
  printf 'Refusing to overwrite non-empty output directory: %s\n' "$OUTPUT_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR/validation"
STATUS_PATH="$OUTPUT_DIR/run-status.json"
METADATA_PATH="$OUTPUT_DIR/run-metadata.json"

export PATH="$ROCM_VENV/bin:$PATH"
export HIP_VISIBLE_DEVICES="$GPU_ID"
export LD_LIBRARY_PATH="$SITE_PACKAGES/torch/lib:$SITE_PACKAGES/_rocm_sdk_core/lib:$SITE_PACKAGES/_rocm_sdk_core/lib/host-math/lib:$SITE_PACKAGES/_rocm_sdk_core/lib/rocm_sysdeps/lib:$SITE_PACKAGES/_rocm_sdk_devel/lib:$SITE_PACKAGES/_rocm_sdk_devel/lib/host-math/lib:$SITE_PACKAGES/_rocm_sdk_libraries_gfx110X_all/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

write_status() {
  local state=$1
  local return_code=$2
  "$ROCM_VENV/bin/python" - "$STATUS_PATH" "$state" "$return_code" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

Path(sys.argv[1]).write_text(json.dumps({
    "schema_version": 1,
    "state": sys.argv[2],
    "return_code": int(sys.argv[3]),
    "updated_at": datetime.now(timezone.utc).isoformat(),
}, indent=2) + "\n", encoding="utf-8")
PY
}

on_exit() {
  local return_code=$?
  if [[ $return_code -eq 0 ]]; then
    write_status completed 0
  else
    write_status failed "$return_code"
  fi
}
trap on_exit EXIT
write_status running 0

"$ROCM_VENV/bin/python" - "$METADATA_PATH" "$OPENSPLAT_BIN" "$DATASET_DIR" "$STEPS" "$SAVE_INTERVAL" <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import torch

path, binary, dataset = map(Path, sys.argv[1:4])
commit = subprocess.run(
    ["git", "-C", str(binary.parent.parent), "rev-parse", "HEAD"],
    check=False, capture_output=True, text=True,
).stdout.strip()
payload = {
    "schema_version": 1,
    "started_at": datetime.now(timezone.utc).isoformat(),
    "backend": "OpenSplat HIP",
    "rocm_arch": "gfx1100",
    "steps": int(sys.argv[4]),
    "save_every": int(sys.argv[5]),
    "image_count": sum(p.is_file() for p in (dataset / "images").iterdir()),
    "hip_visible_devices": os.environ["HIP_VISIBLE_DEVICES"],
    "torch": torch.__version__,
    "torch_hip": torch.version.hip,
    "gpu": torch.cuda.get_device_name(0),
    "opensplat_commit": commit or None,
    "quality_status": "awaiting_metrics_and_visual_review",
}
path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

"$OPENSPLAT_BIN" "$DATASET_DIR" \
  -n "$STEPS" \
  -d 1 \
  --num-downscales 0 \
  --val \
  --val-render "$OUTPUT_DIR/validation" \
  -s "$SAVE_INTERVAL" \
  -o "$OUTPUT_DIR/reconstruction.ply" \
  2>&1 | tee "$OUTPUT_DIR/train.log"

"$ROCM_VENV/bin/python" - "$OUTPUT_DIR" <<'PY'
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1])
ply = root / "reconstruction.ply"
if not ply.is_file() or ply.stat().st_size == 0:
    raise SystemExit("OpenSplat completed without a non-empty reconstruction.ply")
digest = hashlib.sha256()
with ply.open("rb") as stream:
    for block in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(block)
metadata_path = root / "run-metadata.json"
payload = json.loads(metadata_path.read_text(encoding="utf-8"))
payload.update({
    "completed_at": datetime.now(timezone.utc).isoformat(),
    "ply_bytes": ply.stat().st_size,
    "ply_sha256": digest.hexdigest(),
})
metadata_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
