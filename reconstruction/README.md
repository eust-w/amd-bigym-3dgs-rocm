# Reconstruction

This directory contains the AMD gfx1100/OpenSplat HIP reconstruction path, the
historical A800 reference path, and a license-free CPU smoke test.

## Pipeline

```text
authorized DL3DV ZIP
  -> safe extraction + known-pose COLMAP/SIFT initialization
  -> OpenSplat HIP 30k on gfx1100
  -> PLY integrity + fail-closed PSNR/SSIM/LPIPS review
  -> Graphdeco SH3 PLY + camera path
  -> Gaussian-to-MuJoCo Sim(3)
  -> walls / floor / ceiling visual layers
  -> BiGym three-camera acceptance
```

The AMD-native path pins OpenSplat revision
`9fb62fde8b7b8c416121d3cbdcda278ffd9682f7`; use
`bin/build_opensplat_rocm_gfx1100.sh`, `bin/reconstruct_rocm_gfx1100.sh`, or
the disconnect-safe `bin/launch_rocm_gfx1100_30k.sh`. The historical A800
runner is retained under `reference/` and `bin/reconstruct.sh`.

The verified combined and three-layer PLY outputs are available from the
[gated Hugging Face release](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell).
Download `ply/*`, `metadata/*`, and `SHA256SUMS`, then verify the files before
running the downstream alignment or BiGym viewer.

## 1. License-safe source acquisition

Accept the current DL3DV terms and authenticate locally first. Never paste a
token into an environment file or command line.

Source access is requested from
[DL3DV/DL3DV-ALL-960P](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-960P).
The experiment pins
[`3K/951f9d...zip`](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-960P/blob/abb4dab0d4b6d93c32e6d901c06c35bad03210fb/3K/951f9db189a7023708b7798e147e04048a84ce039c5761e8ecb1aa65dcb2da86.zip)
at revision `abb4dab0d4b6d93c32e6d901c06c35bad03210fb`; the downloader verifies
its expected SHA-256 before extraction.

```bash
python -m pip install -r reconstruction/requirements-core.txt
hf auth login
make download-reference-data
```

The downloader verifies revision, bytes, SHA-256, ZIP CRC, image count and pose
metadata. Gated data is written beneath `data/private/`, which Git ignores.

## 2. AMD gfx1100 reconstruction

```bash
git clone https://github.com/pierotofy/OpenSplat.git /root/OpenSplat
git -C /root/OpenSplat checkout 9fb62fde8b7b8c416121d3cbdcda278ffd9682f7
export ROCM_VENV=/root/opensplat-env
make build-opensplat-rocm

export DATASET_DIR=/workspace/persistent/rocm3dgs-inputs/dl3dv-kitchen
export RUN_ROOT=/workspace/persistent/rocm3dgs-results
export RUN_ID=kitchen-gfx1100-30k
make launch-rocm-30k
```

See [the AMD-native guide](../docs/05-amd-native-reconstruction.md) for input
layout, persistent-run artifacts, monitoring, and quality-state boundaries.

## 3. Historical A800 reconstruction

Prepare a Python environment with the correct NVIDIA PyTorch build, clone the
pinned gsplat revision, and install the patched BiGym overlay:

```bash
git clone https://github.com/nerfstudio-project/gsplat.git /workspace/gsplat
git -C /workspace/gsplat checkout 4d3a3b69db4de0326f983ccf7b7b255271a17b01
make install-bigym

export SOURCE_ARCHIVE="$PWD/data/private/dl3dv-kitchen/951f9db189a7023708b7798e147e04048a84ce039c5761e8ecb1aa65dcb2da86.zip"
export SOURCE_REPORT="$PWD/data/private/dl3dv-kitchen/source.json"
export GSPLAT_DIR=/workspace/gsplat
export BIGYM_DIR=/workspace/amd-bigym-3dgs/src/bigym
export WORK_ROOT=/workspace/runs/dl3dv-kitchen-a800
reconstruction/bin/reconstruct.sh
```

Both `default` and `mcmc` candidates must complete. The selector requires
PSNR >= 30, SSIM >= 0.92 and LPIPS <= 0.15; otherwise it exits non-zero and
does not authorize formal export.

## 4. CPU smoke

```bash
make smoke-reconstruction
```

This generates a tiny synthetic binary PLY in a temporary directory, exports
all four expected PLYs, verifies their counts and hashes, confirms a clear
central workspace, and checks that the visual shell adds zero physics objects.

## What is proven

- The source was pinned and integrity checked.
- The published scripts are the real reconstruction/export implementation.
- OpenSplat HIP training and PLY export were measured on a real gfx1100 GPU.
- The actual A800 run metrics and output hashes are recorded in `data/manifests`.
- The shell exporter is independently exercised in CI with license-free data.

## What is not proven by CI

- Access to gated DL3DV data;
- availability of an A800 or Radeon GPU in generic CI;
- photographic quality from arbitrary H1 wrist viewpoints;
- ownership or redistributability of upstream demonstrations.
