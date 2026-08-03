# Reconstruction

This directory contains the real A800 reconstruction path used to create the
three-layer kitchen shell, plus a license-free CPU smoke test.

## Pipeline

```text
authorized DL3DV ZIP
  -> safe extraction + known-pose COLMAP/SIFT initialization
  -> gsplat default and MCMC 30k candidates
  -> fail-closed PSNR/SSIM/LPIPS selection
  -> Graphdeco SH3 PLY + camera path
  -> Gaussian-to-MuJoCo Sim(3)
  -> walls / floor / ceiling visual layers
  -> BiGym three-camera acceptance
```

The experiment pinned gsplat revision
`4d3a3b69db4de0326f983ccf7b7b255271a17b01`. The exact historical cloud
runner is retained under `reference/`; `bin/reconstruct.sh` is the portable,
parameterized entrypoint.

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

## 2. A800 reconstruction

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

## 3. CPU smoke

```bash
make smoke-reconstruction
```

This generates a tiny synthetic binary PLY in a temporary directory, exports
all four expected PLYs, verifies their counts and hashes, confirms a clear
central workspace, and checks that the visual shell adds zero physics objects.

## What is proven

- The source was pinned and integrity checked.
- The published scripts are the real reconstruction/export implementation.
- The actual A800 run metrics and output hashes are recorded in `data/manifests`.
- The shell exporter is independently exercised in CI with license-free data.

## What is not proven by CI

- Access to gated DL3DV data;
- availability of an A800 or Radeon GPU;
- photographic quality from arbitrary H1 wrist viewpoints;
- ownership or redistributability of upstream demonstrations.
