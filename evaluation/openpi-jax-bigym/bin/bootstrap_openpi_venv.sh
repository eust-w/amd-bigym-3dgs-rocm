#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

test -d "$OPENPI_DIR/.git" || fail "run bootstrap_sources.sh first"

POLICY_BASE_PYTHON=${POLICY_BASE_PYTHON:-/opt/venv/bin/python}
test -x "$POLICY_BASE_PYTHON" || POLICY_BASE_PYTHON=$(command -v python3.12 || true)
test -n "$POLICY_BASE_PYTHON" || fail "Python 3.12 is required"
test "$($POLICY_BASE_PYTHON -c 'import sys; print(sys.version_info[:2] == (3, 12))')" = True \
  || fail "AMD JAX wheel requires Python 3.12"

mkdir -p "$(dirname "$POLICY_VENV")" "$RUNTIME_EVIDENCE_DIR"
if test ! -x "$POLICY_PYTHON"; then
  "$POLICY_BASE_PYTHON" -m venv "$POLICY_VENV"
fi

PY="$POLICY_PYTHON"
PIP=("$PY" -m pip)
RECEIPT="$POLICY_VENV/.openpi-rocm-${OPENPI_COMMIT}.installed"

if test ! -f "$RECEIPT"; then
  "${PIP[@]}" install --upgrade pip setuptools wheel
  "${PIP[@]}" install \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.0.2/jax_rocm7_pjrt-0.6.0-py3-none-manylinux_2_28_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.0.2/jax_rocm7_plugin-0.6.0-cp312-cp312-manylinux_2_28_x86_64.whl \
    jax==0.6.0 jaxlib==0.6.0 'scipy>=1.11.1' 'numpy>=1.26,<2.3.0'
  "${PIP[@]}" install --no-deps ml-dtypes==0.5.4
  "${PIP[@]}" install --index-url https://download.pytorch.org/whl/cpu \
    torch==2.7.1 torchvision==0.22.1

  FILTERED_REQUIREMENTS="$RUNTIME_EVIDENCE_DIR/openpi-rocm-venv-requirements.txt"
  grep -v -E '^\s*(jax\[|jax==|jaxlib|ml-dtypes|torch==|torchvision|lerobot\[|-e packages/openpi-client)|^https://repo.radeon.com' \
    "$OPENPI_DIR/requirements_rocm.txt" > "$FILTERED_REQUIREMENTS"
  "${PIP[@]}" install -r "$FILTERED_REQUIREMENTS"
  "${PIP[@]}" install -e "$OPENPI_DIR/packages/openpi-client"
  "${PIP[@]}" install \
    av==15.1.0 datasets==4.8.5 pyarrow==25.0.0 pandas==2.3.3 \
    draccus==0.10.0 gymnasium==1.3.0 jsonlines==4.0.0 \
    opencv-python==4.11.0.86 opencv-python-headless==4.11.0.86
  "${PIP[@]}" install --index-url https://pypi.org/simple torchcodec==0.5
  "${PIP[@]}" install --no-deps lerobot==0.6.0
  "${PIP[@]}" install -e "$OPENPI_DIR" --no-deps

  TRANSFORMERS_DIR=$(
    "$PY" -c 'import os, transformers; print(os.path.dirname(transformers.__file__))'
  )
  cp -R "$OPENPI_DIR/src/openpi/models_pytorch/transformers_replace/." "$TRANSFORMERS_DIR/"
  printf '%s\n' "$OPENPI_COMMIT" > "$RECEIPT"
fi

export ROCM_PATH=${ROCM_PATH:-/opt/rocm}
export LD_LIBRARY_PATH="$ROCM_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export ROCR_VISIBLE_DEVICES=$POLICY_GPU
export HIP_VISIBLE_DEVICES=$POLICY_GPU
"$PY" - <<'PY'
import jax
import torch

devices = jax.devices()
print("jax", jax.__version__)
print("devices", devices)
print("torch", torch.__version__)
if not devices or "rocm" not in type(devices[0]).__name__.lower():
    raise SystemExit("AMD JAX ROCm device was not detected")
if torch.version.hip is not None:
    raise SystemExit("The OpenPI process must use CPU torch to avoid two ROCm stacks")
PY

printf 'OPENPI_VENV_READY python=%s receipt=%s\n' "$PY" "$RECEIPT"
