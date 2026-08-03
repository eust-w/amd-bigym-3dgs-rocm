#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SOURCE_DIR=${1:-${OPENSPLAT_SOURCE_DIR:-/root/OpenSplat}}
ROCM_VENV=${ROCM_VENV:-/root/opensplat-env}
BUILD_DIR=${OPENSPLAT_BUILD_DIR:-$SOURCE_DIR/build}
INCLUDE_OVERLAY=${ROCM_INCLUDE_OVERLAY:-/root/rocm-include-overlay}
ROCM_ARCH=${ROCM_ARCH:-gfx1100}
BUILD_JOBS=${BUILD_JOBS:-8}
EXPECTED_COMMIT=9fb62fde8b7b8c416121d3cbdcda278ffd9682f7
PATCH_FILE="$REPO_ROOT/patches/opensplat-1.1.5-rocm-gfx1100.patch"

if [[ "$ROCM_ARCH" != gfx1100 ]]; then
  printf 'This build contract is pinned to gfx1100, got %s\n' "$ROCM_ARCH" >&2
  exit 2
fi
for executable in cmake ninja git rocminfo; do
  command -v "$executable" >/dev/null || {
    printf 'Missing build dependency: %s\n' "$executable" >&2
    exit 1
  }
done
if ! rocminfo 2>/dev/null | grep -q 'gfx1100'; then
  printf 'No gfx1100 agent is visible to ROCm.\n' >&2
  exit 1
fi
if [[ ! -x "$ROCM_VENV/bin/rocm-sdk" ]]; then
  printf 'TheRock ROCm development environment is missing: %s\n' "$ROCM_VENV" >&2
  exit 1
fi
if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  printf 'OpenSplat Git checkout is missing: %s\n' "$SOURCE_DIR" >&2
  exit 1
fi
if [[ $(git -C "$SOURCE_DIR" rev-parse HEAD) != "$EXPECTED_COMMIT" ]]; then
  printf 'OpenSplat must be pinned to %s\n' "$EXPECTED_COMMIT" >&2
  exit 1
fi

if git -C "$SOURCE_DIR" apply --check "$PATCH_FILE" 2>/dev/null; then
  git -C "$SOURCE_DIR" apply "$PATCH_FILE"
elif ! git -C "$SOURCE_DIR" apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
  printf 'Patch does not apply cleanly: %s\n' "$PATCH_FILE" >&2
  exit 1
fi

ROCM_ROOT=$("$ROCM_VENV/bin/rocm-sdk" path --root)
TORCH_PREFIX=$(
  "$ROCM_VENV/bin/python" -c 'import torch; print(torch.utils.cmake_prefix_path)'
)

mkdir -p "$INCLUDE_OVERLAY"
ln -sfn "$ROCM_ROOT/include/hip" "$INCLUDE_OVERLAY/hip"

export PATH="$ROCM_VENV/bin:$PATH"
export HIP_PATH="$ROCM_ROOT"
export ROCM_HOME="$ROCM_ROOT"
export PYTORCH_ROCM_ARCH="$ROCM_ARCH"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DGPU_RUNTIME=HIP \
  -DHIP_PATH="$ROCM_ROOT" \
  -DROCM_ROOT="$ROCM_ROOT" \
  -DCMAKE_HIP_COMPILER="$ROCM_ROOT/llvm/bin/clang++" \
  -DCMAKE_HIP_ARCHITECTURES="$ROCM_ARCH" \
  -DCMAKE_HIP_FLAGS="-I$INCLUDE_OVERLAY" \
  -DCMAKE_PREFIX_PATH="$TORCH_PREFIX;$ROCM_ROOT" \
  -DOPENSPLAT_BUILD_SIMPLE_TRAINER=ON \
  -DOPENSPLAT_USE_FAST_MATH=OFF

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS"
"$BUILD_DIR/opensplat" --version
