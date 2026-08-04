# Canonical reconstruction

This directory contains the portable reconstruction and validation path for the
canonical DL3DV commercial-kitchen shell.

```text
authorized DL3DV-ALL-2K scene
  -> verified ZIP and known camera poses
  -> gsplat MCMC scheduled-r20, 60k steps, seed 42, 2M cap
  -> Gaussian-to-MuJoCo Sim(3) alignment
  -> walls / metric light floor / ceiling layers
  -> strict BiGym head and wrist camera rendering
```

The source is
[`4K/90e70328...zip`](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-2K/blob/e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c/4K/90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947.zip)
at revision `e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c`.

## Authorized source download

```bash
python -m pip install -r reconstruction/requirements-core.txt
hf auth login
make download-reference-data
```

The downloader validates revision, file size, SHA-256, ZIP CRC, source images
and camera metadata. Credentials remain in the local Hugging Face store.

## Reconstruction

```bash
export SOURCE_ARCHIVE="$PWD/data/private/dl3dv-kitchen/90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947.zip"
export SOURCE_REPORT="$PWD/data/private/dl3dv-kitchen/source.json"
export GSPLAT_DIR=/workspace/gsplat
export BIGYM_DIR=/workspace/amd-bigym-3dgs/src/bigym
export WORK_ROOT=/workspace/runs/dl3dv-commercial-kitchen-a800
reconstruction/bin/reconstruct.sh
```

The canonical outputs and exact hashes are published in the
[manually gated shell repository](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell)
and locked in `data/manifests/a800-reconstruction.public.json`.

## CPU contract test

```bash
make smoke-reconstruction
```

This verifies the exporter and non-physics visual-shell contract with a tiny
license-free synthetic fixture. It does not establish GPU reconstruction or
human visual acceptance. The canonical package remains
`technical_pass_visual_approval_pending`.
