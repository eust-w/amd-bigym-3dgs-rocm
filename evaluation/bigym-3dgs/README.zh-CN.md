# AMD 上与模型无关的 BiGym + 3DGS 闭环评测

该目录负责统一的仿真评测侧：BiGym/MuJoCo、ROCm PyTorch + gsplat、AMD
3DGS 厨房壳、闭环执行、三相机 MP4、完整轨迹、原子 manifest、哈希和结果校验。

推理实现不再和评测代码混在一起。统一接口见
[`../../inference/PROTOCOL.md`](../../inference/PROTOCOL.md)，第三方实现放在
`inference/third_party/<provider>/`。当前提供 OpenPI JAX 参考适配器，但评测器
不再检查 OpenPI 或 JAX 专属字段。

## 运行结构

```text
第三方推理进程                         BiGym 评测进程
/health + /process_frame   <------->  MuJoCo + 严格 3DGS 三相机
模型/权重/推理框架                     录像 + 轨迹 + manifest + 校验
```

代码可以放在同一个仓库，运行时仍需保持两个进程，避免 JAX ROCm 与
PyTorch/gsplat ROCm 在同一 Python 进程中冲突。

## 快速开始

```bash
export AMD_PIPELINE_ROOT=/workspace/amd-bigym-3dgs-rocm
export INFERENCE_PROVIDER=openpi-jax
export INFERENCE_BASE_URL=http://127.0.0.1:7891
export INFERENCE_GPU=0
export SIM_GPU=0

./evaluation/bigym-3dgs/bin/preflight_amd.sh
./evaluation/bigym-3dgs/bin/bootstrap_bigym_source.sh
export VENV=/workspace/amd-bigym-3dgs/.venv
./evaluation/bigym-3dgs/bin/bootstrap_bigym_runtime.sh
hf auth login
./evaluation/bigym-3dgs/bin/download_shell.sh

# 单独启动一个第三方推理服务后：
./evaluation/bigym-3dgs/bin/probe_inference.sh
./evaluation/bigym-3dgs/bin/run_eval.sh smoke
./evaluation/bigym-3dgs/bin/run_eval.sh formal
```

标准比较口径仍是 32 个不同 seed；代码支持任意正整数条数。每条 episode 都会
保存 head、left wrist、right wrist 三路视频、逐步 JSONL、动作前后状态、
reward/done/info、请求 ID、推理耗时、原子 manifest 和 SHA-256。任务失败轨迹
保留用于诊断，但不能冒充成功示范数据。

完整目录、验收门禁和兼容入口说明见 [English README](README.md)。
