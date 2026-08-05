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
| Task | `DishwasherUnloadCutleryLong`; formal contract: 32 episodes/seeds `0..31`; custom runs: any positive count |

The complete machine-readable contract is in
[`VERSION_LOCK.json`](VERSION_LOCK.json). The shell downloader uses the actual
AMD Hub `scene-shell-profile.json` and its accompanying live-camera-calibrated
`alignment.json`; it does not reuse the older A800 profile under `configs/`.

## Live BiGym camera calibration

The first AMD runtime probe proved that the PLY and renderer were healthy, but
the original coarse room transform placed the live head/wrist rig outside the
useful capture path. The result was technically valid yet visibly blurred. The
checked-in [`src/calibrate_amd_shell.py`](src/calibrate_amd_shell.py) fixes this
without changing the Gaussian geometry:

1. convert the authoritative 352-camera OpenSplat export to camera-to-world
   poses;
2. measure the live BiGym head, left-wrist and right-wrist cameras at reset;
3. fit an upright metric Sim(3) transform over all capture-path anchors;
4. require all three live cameras to remain close to the captured trajectory;
5. use a metric procedural floor instead of treating floor-like Gaussian
   outliers as trustworthy geometry.

The reproduced AMD fit selected capture camera `296`, final scale
`3.837305195946387`, maximum live-camera path distance `0.18809790503955182 m`,
maximum rotation error `46.81137337427233°`, and room height
`3.4049458499049234 m`. Head and both wrist frames were then reviewed as clear
and continuous before the multi-seed smoke run was started.

The recorded bounded AMD smoke result is
[`evidence/amd-smoke-20260804.json`](evidence/amd-smoke-20260804.json): three
distinct seeds, 100 steps per seed, 30 real policy requests, `213.386 ms` mean
policy latency, and `0/3` task successes. This passes the runtime and visual
integration gates; it does not claim policy task success or completion of the
32-episode formal benchmark. It was produced by the earlier summary recorder;
the full recorder described below requires a new run and does not retroactively
invent missing wrist video, state, action or reward records.

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

When reusing an already-built HIP gsplat binary, set
`GSPLAT_PREBUILT_DIR=/absolute/path/to/gsplat_cuda`. The evaluator imports the
binary directly, verifies `CameraModelType`, records its SHA-256, and avoids a
spurious CUDA-toolkit JIT rebuild. Fresh hosts should run
`bootstrap_bigym_runtime.sh`, which builds the pinned gsplat 1.4.0 patch.

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

# A non-benchmark run may use any positive episode count.
N_EPISODES=8 RUN_NAME=custom-8-full-v2 \
  ./evaluation/openpi-jax-bigym/bin/run_eval.sh custom
```

`run_eval.sh` keeps human review pending by default. After reviewing the
recorded initial/final head and wrist PNGs, update only the summary from the
already validated artifacts; do not rerun the simulator merely to record the
human verdict:

```bash
python3 evaluation/openpi-jax-bigym/src/summarize_results.py \
  --results "$AMD_EVAL_ROOT/results/smoke-full-v2/dishwasher_unload_cutlery_long/results.json" \
  --recording-validation "$AMD_EVAL_ROOT/results/smoke-full-v2/recording-validation.json" \
  --output "$AMD_EVAL_ROOT/results/smoke-full-v2/evaluation-summary.json" \
  --expected-episodes 3 \
  --human-visual-review passed  # use failed when any view is blank/blurred
```

The smoke run is three episodes. The version-locked formal benchmark is 32
distinct reset seeds. `N_EPISODES` may override either default, or be supplied
with `custom`; such a run is valid evaluation data but is not the comparable
formal-32 benchmark.

Every reset and transition is now written immediately to append-only JSONL.
Each transition explicitly links the 16D state before the action, the 16D state
after the action, MuJoCo time before/after, the model/environment/clipped
actions and mask, reward, success/done flags, simulator info, and the record
indices of the observations before and after the action. The three camera
frames on a transition are therefore unambiguously the observation after that
action. Request ID, client PNG/HTTP latency, and server image-decode,
JAX-inference and serialization timing are retained as well. Head, left-wrist
and right-wrist observations are synchronized per episode.
Task failures are finalized as complete diagnostic recordings, never discarded
or presented as successes.

`RESUME=1` skips already finalized episodes. An interrupted simulator cannot be
resumed mid-state safely, so `RESTART_INTERRUPTED=1` preserves its partial files
under `incomplete-attempts/` and replays that seed from reset. Set a new
`RUN_NAME` to keep independent evaluation populations separate.

## Output and acceptance

```text
$AMD_EVAL_ROOT/results/
├── runtime/
│   ├── amd-preflight.env
│   ├── rocminfo.txt
│   ├── rocm-smi-before.txt
│   ├── policy-contract-probe.json
│   └── policy-server.log
├── smoke-full-v2/
│   ├── evaluation-summary.json
│   ├── recording-validation.json
│   └── dishwasher_unload_cutlery_long/
└── formal-full-v2/
    ├── evaluation-summary.json
    ├── recording-validation.json
    └── dishwasher_unload_cutlery_long/
        ├── episodes/episode-000000/
        │   ├── steps.jsonl       # reset/events/transitions, flushed per record
        │   ├── manifest.json     # atomic status, hashes and video metadata
        │   ├── evidence/         # three-camera initial/final PNGs
        │   └── videos/
        │       ├── head.mp4
        │       ├── left_wrist.mp4
        │       └── right_wrist.mp4
        ├── incomplete-attempts/  # preserved only when a run was interrupted
        └── results.json          # atomically updated after each episode
```

Each run also writes `evaluation-summary.json` beside the task directory.
The gates are deliberately separate:

1. `/health` only proves that the HTTP process is ready.
2. `policy-contract-probe.json` proves one real checkpoint inference returned a
   finite `10x16` action chunk.
3. `results.json` proves the policy was closed over the real BiGym environment
   with strict 3DGS rendering.
4. `recording-validation.json` proves all episode manifests, JSONL transitions,
   action/observation alignment, code/checkpoint provenance, three-camera
   dimensions/frame counts, full decode and hashes are complete.
5. `evaluation-summary.json` proves episode counts, latency, failure categories
   and the full-recording gate are complete.
6. `human_visual_review_status=passed` proves that the recorded three-camera
   images were explicitly reviewed; the default remains `pending`.

This is an evaluation trace, not automatically a successful imitation-learning
dataset. Filter or label task failures explicitly before downstream training;
the current public AMD smoke evidence is `0/3` successes.

Run the license-free contract tests locally or in CI:

```bash
./evaluation/openpi-jax-bigym/bin/verify.sh
```

## License and data boundary

Scripts in this directory are Apache-2.0 with the repository. The OpenPI,
BiGym, checkpoint, DL3DV source and derived shell retain their upstream terms.
No model weights, PLY files, source frames, credentials or private endpoints
are committed here.
