# Data plane

This directory keeps the **data contract** beside the code without illegally
redistributing gated inputs or derived scene assets.

## Tracked in Git

| Path | Purpose |
| --- | --- |
| `manifests/dl3dv-kitchen-source.public.json` | Pinned source identity, size, hash and license gate |
| `manifests/a800-reconstruction.public.json` | Sanitized training metrics and expected shell hashes |
| `manifests/cutlery32-dataset.public.json` | LeRobot v3 collection shape and acceptance counts |
| `samples/synthetic-room/README.md` | License-free CI fixture contract |

## Never tracked in Git

- DL3DV images, videos or the source ZIP;
- complete DL3DV-derived PLYs or checkpoints;
- BiGym official demonstrations and their real UUIDs;
- the full 32-episode LeRobot package;
- cloud addresses, SSH configuration or access credentials.

Run `reconstruction/bin/download_reference_data.sh` after independently
accepting the DL3DV terms. The downloader reads only the local Hugging Face
credential store and verifies the pinned revision, byte count, SHA-256 and ZIP
CRC before producing `source.json`.

The default private-data root is `data/private/`, which is ignored by Git.
