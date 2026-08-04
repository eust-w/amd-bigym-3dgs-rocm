# OpenPI JAX inference + BiGym 3DGS evaluation on AMD

This directory is the reproducible evaluation lane for the
`DishwasherUnloadCutleryLong` π0.5 LoRA checkpoint. It keeps the policy server,
BiGym simulator and AMD 3DGS renderer as separate runtime processes so JAX and
PyTorch/gsplat do not load conflicting ROCm stacks into one process.

## Pinned inputs

| Component | Pinned value |
| --- | --- |
| OpenPI server | [`WuChao-2024/openpi_lerobot_plus`](https://github.com/WuChao-2024/openpi_lerobot_plus), commit `9a98f3276fb6b95474ae07ff184ebd5f31686548` |
| π0.5 checkpoint | [`WuChao-Cauchy/pi05_ckpts`](https://huggingface.co/WuChao-Cauchy/pi05_ckpts), revision `b20a8efaacc6c8e607f2ccb11f47bb2623f5c947` |
| BiGym client | [`WuChao-2024/bigym_plus`](https://github.com/WuChao-2024/bigym_plus), commit `d12937686833467b5013ac47a834cf4b6f5a9d53` |
| AMD visual shell | [`eustance/amd-bigym-3dgs-kitchen-shell`](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell/tree/amd-rocm-w7900d-20260804), revision `amd-rocm-w7900d-20260804` |
| Task | `DishwasherUnloadCutleryLong`, 32 formal episodes, seeds `0..31` |

The complete machine-readable contract is in
[`VERSION_LOCK.json`](VERSION_LOCK.json). The shell downloader uses the actual
AMD Hub `scene-shell-profile.json` and its accompanying `alignment.json`; it
does not reuse the older A800 profile under `configs/`.

## Runtime split

| Process | GPU | Runtime | Purpose |
| --- | --- | --- | --- |
| Policy server | `POLICY_GPU=0` | JAX ROCm 0.6.0 | loads the 9.5 GB Orbax LoRA checkpoint and serves `/process_frame` |
| BiGym client | `SIM_GPU=0` on one-GPU hosts; `1` when available | PyTorch ROCm + patched gsplat 1.4.0 | renders strict head/wrist 3DGS observations and steps MuJoCo |

Two `gfx1100` devices are preferred, but a single 48 GB-class device is
supported by keeping JAX and PyTorch/gsplat in separate processes and running a
strict smoke memory gate before the formal benchmark. The default JAX pool is
75%; the visual renderer uses the remaining memory. A single process must never
import both ROCm stacks.

## Run

Use a persistent AMD workspace. Large model and shell artifacts are downloaded
there, never into this Git repository.

```bash
export AMD_EVAL_ROOT=/workspace/amd-bigym-openpi-eval
export POLICY_GPU=0
export SIM_GPU=0                 # set to 1 only when a second gfx1100 exists

./evaluation/openpi-jax-bigym/bin/preflight_amd.sh
./evaluation/openpi-jax-bigym/bin/bootstrap_sources.sh

# No Conda is required. The bootstrap creates an isolated Python 3.12 policy
# venv, installs the pinned AMD JAX wheels and keeps torch CPU-only there.
export POLICY_BASE_PYTHON=/opt/venv/bin/python

# Reuse a verified ROCm PyTorch environment when one already exists:
export VENV=/workspace/amd-bigym-3dgs/.venv
./evaluation/openpi-jax-bigym/bin/bootstrap_bigym_runtime.sh

# The downloader also discovers the common /opt/venv/bin/hf location.
hf auth login
./evaluation/openpi-jax-bigym/bin/download_artifacts.sh
```

Start the real policy server in terminal A:

```bash
./evaluation/openpi-jax-bigym/bin/serve_policy.sh \
  2>&1 | tee /workspace/amd-bigym-openpi-eval/results/runtime/policy-server.log
```

Validate it in terminal B, then run the closed loop:

```bash
./evaluation/openpi-jax-bigym/bin/probe_policy.sh
./evaluation/openpi-jax-bigym/bin/run_eval.sh smoke
./evaluation/openpi-jax-bigym/bin/run_eval.sh formal
```

The smoke run is three episodes. The formal run is 32 distinct reset seeds.
Every episode retains a head-camera H.264 video plus initial/final head and
wrist PNGs. Failed policy replays remain in the diagnostic result set and are
classified; they are not silently counted as successes.

## Output and acceptance

```text
$AMD_EVAL_ROOT/results/
├── runtime/
│   ├── amd-preflight.env
│   ├── rocminfo.txt
│   ├── rocm-smi-before.txt
│   ├── policy-contract-probe.json
│   └── policy-server.log
├── smoke/dishwasher_unload_cutlery_long/
└── formal/dishwasher_unload_cutlery_long/
    ├── evidence/                 # three-camera initial/final PNGs
    ├── videos/                   # head policy-view H.264 videos with 3DGS
    └── results.json              # episode-level raw result
```

Each run also writes `evaluation-summary.json` beside the task directory.
The gates are deliberately separate:

1. `/health` only proves that the HTTP process is ready.
2. `policy-contract-probe.json` proves one real checkpoint inference returned a
   finite `10x16` action chunk.
3. `results.json` proves the policy was closed over the real BiGym environment
   with strict 3DGS rendering.
4. `evaluation-summary.json` proves episode counts, latency and failure
   categories are complete.
5. Human review of the recorded three-camera images is still required before
   claiming the room shell is visually accepted.

Run the license-free contract tests locally or in CI:

```bash
./evaluation/openpi-jax-bigym/bin/verify.sh
```

## License and data boundary

Scripts in this directory are Apache-2.0 with the repository. The OpenPI,
BiGym, checkpoint, DL3DV source and derived shell retain their upstream terms.
No model weights, PLY files, source frames, credentials or private endpoints
are committed here.
