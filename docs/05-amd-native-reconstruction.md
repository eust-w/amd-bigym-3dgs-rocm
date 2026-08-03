# AMD gfx1100 原生 3DGS 重建

本分支把训练侧从 NVIDIA A800/gsplat 切换为 AMD Radeon
`gfx1100`/OpenSplat HIP。A800 清单仍作为历史基准保留，但不是这条入口的运行
依赖。

## 已实测边界

- 硬件：AMD Radeon PRO W7900D，`gfx1100`；
- 后端：OpenSplat 1.1.5 commit
  `9fb62fde8b7b8c416121d3cbdcda278ffd9682f7`，HIP；
- 已有独立 10k 验证：816,948 个 Gaussian，PSNR `32.153`，SSIM
  `0.963865`；
- 该 10k 结果只证明训练与 PLY 导出链路，SSIM 略低于严格目标 `0.965`，
  LPIPS 和完整自由视角仍待验收，因此不能标记为照片级完成。

仓库公开清单中的 355 张场景与上述 332 张 AMD 验证场景不是同一个场景。
复现时必须通过 source manifest、scene object 和 SHA-256 区分，不能把指标互换。

## 1. 准备 ROCm 与 OpenSplat

需要能够被 `rocminfo` 识别为 `gfx1100` 的 ROCm/TheRock Python 环境：

```bash
git clone https://github.com/pierotofy/OpenSplat.git /root/OpenSplat
git -C /root/OpenSplat checkout 9fb62fde8b7b8c416121d3cbdcda278ffd9682f7

export ROCM_VENV=/root/opensplat-env
make build-opensplat-rocm
```

构建脚本会拒绝其他 GPU 架构、错误 OpenSplat revision 或不可逆的补丁冲突。

## 2. 准备 COLMAP 输入

输入必须具有以下结构：

```text
dataset/
├── images/
└── sparse/0/
    ├── cameras.bin
    ├── images.bin
    └── points3D.bin
```

若复现仓库中的精确公开场景，先执行 `make download-reference-data`，再使用
`reconstruction/src/prepare_dl3dv_scene.py` 生成已知位姿 COLMAP 数据。受限制的
DL3DV ZIP 与图片只放在 Git 忽略的私有目录。

## 3. 启动 30k 训练

前台运行：

```bash
export DATASET_DIR=/workspace/persistent/rocm3dgs-inputs/dl3dv-kitchen
export OUTPUT_DIR=/workspace/persistent/rocm3dgs-results/kitchen-gfx1100-30k
export TRAIN_STEPS=30000
make reconstruct-rocm
```

通过 Jupyter/SSH 启动可断线续跑的进程：

```bash
export DATASET_DIR=/workspace/persistent/rocm3dgs-inputs/dl3dv-kitchen
export RUN_ROOT=/workspace/persistent/rocm3dgs-results
export RUN_ID=kitchen-gfx1100-30k
make launch-rocm-30k
```

脚本拒绝覆盖已有输出。每次运行写入：

- `launcher.pid`、`launcher.log`：后台进程与首层日志；
- `run-status.json`：`running`、`completed` 或 `failed`；
- `run-metadata.json`：GPU、HIP、OpenSplat revision、图片数、steps 和最终 PLY
  SHA-256；
- `train.log`、`validation/`、`reconstruction.ply`：训练与结果。

## 4. 状态与质量判定

```bash
RUN=/workspace/persistent/rocm3dgs-results/kitchen-gfx1100-30k
kill -0 "$(cat "$RUN/launcher.pid")" && echo running
tail -n 30 "$RUN/launcher.log"
rocm-smi --showuse --showmemuse
```

`run-status.json=completed` 只表示训练与 PLY 完整写出。正式房间壳还必须继续做
held-out PSNR/SSIM/LPIPS、PLY 健康检查、Gaussian-to-MuJoCo 对齐和 H1 三相机
自由视角验收；在这些完成前，`quality_status` 保持
`awaiting_metrics_and_visual_review`。
