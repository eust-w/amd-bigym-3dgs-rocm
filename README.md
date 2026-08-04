# AMD Radeon BiGym + 3DGS kitchen

[English](README.md) | [中文](README.zh-CN.md) ·
[AMD/ROCm `main`](https://github.com/eust-w/amd-bigym-3dgs-rocm/tree/main) ·
[A800/CUDA `a800`](https://github.com/eust-w/amd-bigym-3dgs-rocm/tree/a800)

This is the AMD Radeon/ROCm implementation branch for replaying and validating
BiGym `DishwasherUnloadCutleryLong` with a visual-only 3D Gaussian Splatting
kitchen shell. The verified NVIDIA A800/CUDA reference is preserved unchanged
on the [`a800` branch](https://github.com/eust-w/amd-bigym-3dgs-rocm/tree/a800).

Both branches use one canonical data/shell identity. Superseded scene and
collection identities are not supported.

## Preview from the canonical material

| Aligned 3DGS room shell | Selected source trajectory views |
| --- | --- |
| ![Aligned light-floor 3DGS commercial kitchen shell](docs/images/canonical-shell-preview.png) | ![DL3DV commercial-kitchen source trajectory contact sheet](docs/images/canonical-source-contact-sheet.jpg) |

![Six-second excerpt from the canonical merged cam_high replay stream](docs/images/cutlery-cam-high-preview.gif)

The GIF is a six-second excerpt from the verified merged `cam_high` stream. It
is included as review evidence, not as a replacement for the gated full video
or human review of all three cameras.

### Reproduced on AMD Radeon

![Held-out DL3DV reference beside the 15,000-step AMD ROCm reconstruction](docs/images/amd-rocm-heldout-vs-reference.png)

The left half is the held-out `1920x1080` source frame and the right half is
the render produced on an AMD Radeon PRO W7900D after 15,000 OpenSplat/HIP
steps. The clear-preview gate passed at PSNR `27.9066` and SSIM `0.9370`.
Obvious projected streak Gaussians and one all-camera-invisible spatial outlier
were removed before the room-shell export.

## Branch and evidence boundary

| Branch or artifact | Hardware stage | Current claim |
| --- | --- | --- |
| `main` | AMD Radeon PRO W7900D `gfx1100`, ROCm/HIP | Canonical 352-image reconstruction reproduced; cleaned PLY, clear held-out render and collision-free room-shell gates passed |
| `a800` | NVIDIA A800, CUDA 12.8 | Locked reference: shell reconstruction and 32-episode collection passed technical checks |
| Hugging Face dataset | Produced on A800 | 32 episodes and three merged camera videos; visual status `awaiting_visual_approval` |
| Hugging Face shell | A800 `main` + AMD branch | Exact A800 reference retained; independently reproduced AMD PLY, layers, alignment, receipt and preview published on a separate HF branch |

The canonical reconstruction has now been reproduced on Radeon. This does
**not** claim that the A800 32-episode collection has also been replayed on AMD:
that downstream acceptance still requires native gsplat rasterization, strict
three-camera replay, full-video decode and separate human visual review.

Machine-readable status is recorded in
[`evidence/amd-rocm-main-status.json`](evidence/amd-rocm-main-status.json). The
A800 baseline remains explicit in
[`evidence/a800-reference-validation-summary.json`](evidence/a800-reference-validation-summary.json).

## Canonical inputs

| Artifact | Canonical value |
| --- | --- |
| LeRobot v3 reference | [eustance/openSource_AMD_AI_DevMaster_Hackathon_202608](https://huggingface.co/datasets/eustance/openSource_AMD_AI_DevMaster_Hackathon_202608) |
| Dataset path | `bigym-3dgs-light-floor-replay-plan-v2-20260802/dishwasher_unload_cutlery_long` |
| 3DGS shell | [eustance/amd-bigym-3dgs-kitchen-shell](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell) |
| DL3DV source | [DL3DV/DL3DV-ALL-2K](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-2K), revision `e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c` |
| Scene hash | `90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947` |
| Combined shell | 862,104 Gaussians, SHA-256 `086f1f5757523db94349de16707806e74a65bac35b24d9e4e7437639164738a7` |
| AMD cleaned reconstruction | 1,458,354 Gaussians, SHA-256 `d49bcf7219f63a92ee0d40f8d86e618176892ec89853fecc5e217829bff42b9b` |
| AMD shell package | [HF branch `amd-rocm-w7900d-20260804`](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell/tree/amd-rocm-w7900d-20260804) |

Both Hugging Face repositories are manually gated because the canonical
material remains subject to the current DL3DV and upstream terms.

## AMD/ROCm quick start

Target environment:

- AMD Radeon GPU reporting `gfx1100`;
- ROCm-enabled PyTorch on an AMD Radeon `gfx1100` device;
- OpenSplat commit `9fb62fde8b7b8c416121d3cbdcda278ffd9682f7`
  for reconstruction;
- Python 3.12, MuJoCo 3.10, BiGym 4.1 and gsplat 1.4 for the
  downstream runtime renderer.

Build the native OpenSplat HIP trainer, download the exact gated source, and
run the end-to-end AMD reconstruction:

```bash
git clone https://github.com/pierotofy/OpenSplat.git /root/OpenSplat
git -C /root/OpenSplat checkout --detach \
  9fb62fde8b7b8c416121d3cbdcda278ffd9682f7
export OPENSPLAT_SOURCE=/root/OpenSplat
make build-opensplat

hf auth login
make download-reference-data
cp reconstruction/config/rocm.env.example .rocm.env
set -a && source .rocm.env && set +a
make reconstruct-rocm
```

The generated receipt is accepted only with status
`amd_rocm_reproduction_passed`. See
[`reconstruction/README.md`](reconstruction/README.md) for the exact gates.

Download the gated canonical shell, verify it against
[`data/manifests/a800-reconstruction.public.json`](data/manifests/a800-reconstruction.public.json),
and stage its exact layers:

```bash
hf auth login
hf download eustance/amd-bigym-3dgs-kitchen-shell \
  --repo-type dataset --local-dir data/private/canonical-shell

export SHELL_WALLS="$PWD/data/private/canonical-shell/walls_fixed_kitchen.ply"
export SHELL_FLOOR="$PWD/data/private/canonical-shell/floor_perimeter.ply"
export SHELL_CEILING="$PWD/data/private/canonical-shell/ceiling_lights.ply"
export SHELL_DIR="$PWD/data/private/amd-runtime-shell"
make stage-shell
```

Run the verified 32-item replay plan only after the native AMD renderer gate
passes:

```bash
export REPLAY_PLAN=/absolute/path/to/cutlery32-replay-plan.json
export DATASET_ROOT=/absolute/path/to/amd-cutlery32
make collect
make validate
```

Failed replays must remain excluded. The published AMD reconstruction receipt
does not promote the separate 32-episode replay stage.

## What is implemented

- isolated ROCm compiler wrapper that does not modify `/opt/rocm`;
- pinned OpenSplat native HIP reconstruction on `gfx1100`;
- held-out PSNR/SSIM reporting and conservative invisible-outlier cleanup;
- `gsplat==1.4.0` `gfx1100` compatibility patch and real rasterization smoke;
- BiGym visual-only shell compositing with zero added MuJoCo physics objects;
- strict `head`/left-wrist/right-wrist rendering with no fallback;
- distinct-demo replay plan verification;
- LeRobot v3 structural, finite-value and full-video decode checks;
- license-safe synthetic reconstruction smoke used by CI.

See [`docs/02-rocm-gsplat.md`](docs/02-rocm-gsplat.md) for the ROCm build
boundary and [`docs/01-end-to-end.md`](docs/01-end-to-end.md) for the coordinate
and compositing path.

## Repository checks

```bash
make verify
make smoke-reconstruction
python scripts/check_markdown_links.py
```

GitHub CI verifies public-file hashes, JSON contracts, both patches, Markdown
links and the license-free shell exporter. The recorded Radeon GPU result is
independently exposed as a machine-readable receipt and immutable hashes.

## License

Repository code is Apache-2.0 unless a file says otherwise. DL3DV source data,
derived shell assets, previews and frames remain subject to CC BY-NC 4.0 plus
the current DL3DV terms. BiGym demonstrations retain their upstream terms.
