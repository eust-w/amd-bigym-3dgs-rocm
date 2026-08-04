# BiGym + DL3DV 3DGS canonical kitchen

[English](README.md) | [中文](README.zh-CN.md)

This repository is the code and public-contract companion for one canonical
BiGym collection. All current configuration, manifests and documentation must
resolve to the following pair:

- dataset: `bigym-3dgs-light-floor-replay-plan-v2-20260802/dishwasher_unload_cutlery_long`;
- shell: DL3DV commercial-kitchen scene
  `90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947`.

All superseded scene and collection identities are deliberately absent from the
current branch.

## Canonical releases

| Artifact | Canonical value |
| --- | --- |
| LeRobot v3 dataset | [eustance/openSource_AMD_AI_DevMaster_Hackathon_202608](https://huggingface.co/datasets/eustance/openSource_AMD_AI_DevMaster_Hackathon_202608) |
| Dataset path | `bigym-3dgs-light-floor-replay-plan-v2-20260802/dishwasher_unload_cutlery_long` |
| 3DGS shell | [eustance/amd-bigym-3dgs-kitchen-shell](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell) |
| Source | [DL3DV/DL3DV-ALL-2K](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-2K), revision `e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c` |
| Runtime | NVIDIA A800 / CUDA |
| Visual status | `awaiting_visual_approval` |

Both Hugging Face repositories are manually gated because the source is
subject to the current DL3DV terms and non-commercial restrictions.

## Verified data contract

- task: `DishwasherUnloadCutleryLong`;
- 32 distinct successful episodes, indices `0..31`;
- 21,018 frames at 20 fps;
- 16-dimensional finite `float32` state and action arrays;
- one merged data Parquet, one 32-row episode-metadata Parquet;
- three merged H.264 videos: `cam_high`, `cam_left_wrist`, and
  `cam_right_wrist`;
- all three videos contain 21,018 frames and pass full decode.

The package passes structural and technical validation. Human visual approval
is still pending; it must not be described as a visually accepted training set.
Exact file hashes are locked in
[`data/manifests/cutlery32-dataset.public.json`](data/manifests/cutlery32-dataset.public.json).

## Verified shell contract

The canonical shell was reconstructed with gsplat MCMC scheduled-r20 for
60,000 steps, seed 42, and a 2,000,000-Gaussian cap. Its combined shell has
862,104 Gaussians:

```text
gaussians_shell.ply
SHA-256 086f1f5757523db94349de16707806e74a65bac35b24d9e4e7437639164738a7
```

The wall, floor, ceiling, combined-shell and alignment hashes are in
[`data/manifests/a800-reconstruction.public.json`](data/manifests/a800-reconstruction.public.json).
The PLY and alignment bytes match the collection receipt. The published
profile was regenerated from the preserved calibrated profile with the same
light neutral metric-floor settings; it is semantically equivalent but not
byte-identical to the lost ephemeral runtime profile.

## Download

Authenticate with a Hugging Face account approved for both gated repositories:

```bash
hf auth login
hf download eustance/amd-bigym-3dgs-kitchen-shell \
  --repo-type dataset --local-dir data/private/canonical-shell
hf download eustance/openSource_AMD_AI_DevMaster_Hackathon_202608 \
  --repo-type dataset \
  --include 'bigym-3dgs-light-floor-replay-plan-v2-20260802/**' \
  --local-dir data/private/canonical-cutlery32
```

Verify downloaded hashes against the two public manifests before training or
evaluation.

## Code paths

- [`reconstruction/`](reconstruction/README.md): authorized source download,
  reconstruction, shell export and validation;
- [`configs/dl3dv-kitchen-cutlery32-profile.json`](configs/dl3dv-kitchen-cutlery32-profile.json):
  canonical shell/profile configuration;
- [`scripts/run_cutlery32.sh`](scripts/run_cutlery32.sh): formal collection
  entrypoint;
- [`scripts/validate_lerobot_v3_collection.py`](scripts/validate_lerobot_v3_collection.py):
  structural and full-video validation;
- [`docs/data-license.md`](docs/data-license.md): license and redistribution
  boundaries.

The AMD ROCm scripts remain a portability path for this canonical workload.
They do not redefine the A800-generated dataset or shell identity.

## Local checks

```bash
make verify
make smoke-reconstruction
```

The source archive, full PLYs and collected dataset are not committed to Git.
They live only in the manually gated Hugging Face repositories.

## License

Repository code is Apache-2.0 unless a file says otherwise. DL3DV source data,
derived shell assets, previews and frames remain subject to CC BY-NC 4.0 plus
the current DL3DV terms. BiGym demonstrations retain their upstream terms.
