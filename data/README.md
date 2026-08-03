# Data plane

This directory keeps the **data contract** beside the code without storing
large scene assets or upstream-gated inputs in Git.

## Tracked in Git

| Path | Purpose |
| --- | --- |
| `manifests/dl3dv-kitchen-source.public.json` | Pinned source identity, size, hash and license gate |
| `manifests/a800-reconstruction.public.json` | Sanitized training metrics and expected shell hashes |
| `manifests/cutlery32-dataset.public.json` | LeRobot v3 collection shape and acceptance counts |
| `samples/synthetic-room/README.md` | License-free CI fixture contract |

## Never tracked in Git

- DL3DV images, videos or the source ZIP;
- complete DL3DV-derived PLYs or checkpoints (the curated PLY shell is released
  separately on Hugging Face);
- BiGym official demonstrations and their real UUIDs;
- the full 32-episode LeRobot package;
- cloud addresses, SSH configuration or access credentials.

Run `reconstruction/bin/download_reference_data.sh` after independently
accepting the DL3DV terms. The downloader reads only the local Hugging Face
credential store and verifies the pinned revision, byte count, SHA-256 and ZIP
CRC before producing `source.json`.

The exact upstream object is
[`3K/951f9d...zip`](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-960P/blob/abb4dab0d4b6d93c32e6d901c06c35bad03210fb/3K/951f9db189a7023708b7798e147e04048a84ce039c5761e8ecb1aa65dcb2da86.zip).
Request access from the
[official dataset page](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-960P)
before running the downloader; this repository does not mirror the ZIP.

The curated derived shell is published separately at
[eustance/amd-bigym-3dgs-kitchen-shell](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell).
It contains `ply/gaussians_shell.ply`, the three layer PLYs, alignment, camera
path, public manifests, previews, and `SHA256SUMS`. Access is manually gated;
the raw DL3DV ZIP is not mirrored there.

```bash
hf download eustance/amd-bigym-3dgs-kitchen-shell \
  --repo-type dataset --include 'ply/*' 'metadata/*' 'SHA256SUMS' \
  --local-dir data/private/amd-bigym-3dgs-kitchen-shell
```

The default private-data root is `data/private/`, which is ignored by Git.
