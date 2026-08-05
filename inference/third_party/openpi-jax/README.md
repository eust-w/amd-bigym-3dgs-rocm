# OpenPI JAX third-party inference provider for AMD

This optional provider adapts the pinned
[`WuChao-2024/openpi_lerobot_plus`](https://github.com/WuChao-2024/openpi_lerobot_plus)
π0.5 LoRA checkpoint to the repository's provider-neutral
[HTTP inference v2 protocol](../../PROTOCOL.md).

It owns only provider-specific concerns:

- pinned OpenPI source and Orbax checkpoint;
- isolated Python 3.12 JAX ROCm environment;
- ROCm-safe Pillow/single-thread Flask adapter;
- provider/checkpoint identity and latency evidence.

BiGym, MuJoCo, the 3DGS shell, trajectory recording and result validation stay
in [`../../../evaluation/bigym-3dgs/`](../../../evaluation/bigym-3dgs/README.md).

## Pinned provider inputs

| Component | Value |
| --- | --- |
| OpenPI source | commit `9a98f3276fb6b95474ae07ff184ebd5f31686548` |
| Checkpoint | `WuChao-Cauchy/pi05_ckpts`, revision `b20a8efaacc6c8e607f2ccb11f47bb2623f5c947` |
| JAX | ROCm 7 wheels, `jax==0.6.0`, Python 3.12 |
| Service | protocol v2 on `/health` and `/process_frame` |

See [`VERSION_LOCK.json`](VERSION_LOCK.json) for the machine-readable contract.

## Run

```bash
export AMD_PIPELINE_ROOT=/workspace/amd-bigym-3dgs-rocm
export INFERENCE_GPU=0
export INFERENCE_HOST=127.0.0.1
export INFERENCE_PORT=7891
export POLICY_BASE_PYTHON=/opt/venv/bin/python

./inference/third_party/openpi-jax/bin/bootstrap.sh
hf auth login
./inference/third_party/openpi-jax/bin/download_checkpoint.sh
./inference/third_party/openpi-jax/bin/serve.sh
```

In another terminal:

```bash
export AMD_PIPELINE_ROOT=/workspace/amd-bigym-3dgs-rocm
export INFERENCE_PROVIDER=openpi-jax
export INFERENCE_BASE_URL=http://127.0.0.1:7891
./evaluation/bigym-3dgs/bin/probe_inference.sh
./evaluation/bigym-3dgs/bin/run_eval.sh smoke
```

The provider venv intentionally uses CPU-only torch. JAX ROCm and
PyTorch/gsplat ROCm remain in separate processes even when they share one GPU.
No source checkout, model weight, PLY, credential or run output is committed.

## Verify the provider package

```bash
./inference/third_party/openpi-jax/bin/verify.sh
```
