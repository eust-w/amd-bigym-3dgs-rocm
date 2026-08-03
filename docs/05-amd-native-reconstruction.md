# AMD gfx1100 原生 3DGS 重建

本分支把训练侧从 NVIDIA A800/gsplat 切换为 AMD Radeon
`gfx1100`/OpenSplat HIP。A800 清单仍作为历史基准保留，但不是这条入口的运行
依赖。

## 2026-08-04 已实测结果

- 硬件：AMD Radeon PRO W7900D，`gfx1100`；
- 后端：OpenSplat 1.1.5 commit
  `9fb62fde8b7b8c416121d3cbdcda278ffd9682f7`，HIP；
- 输入：同一 DL3DV 场景的 332 个注册视角，其中 331 个用于训练，
  `frame_00159.png` 作为 held-out；
- 30k 结果：1,198,821 个 Gaussian，PSNR `33.8325636`、SSIM
  `0.9718575`、LPIPS-Alex `0.0384274`，指标 gate 通过；
- visual-safe 清理：只移除 177 个空间离群点；对 79 个大尺度 Gaussian 的
  候选过滤因引入紫色地面伪影被否决；
- CutleryLong 任务壳：991,213 个 Gaussian，中央工作区可见违规点为 0；
  OpenSplat HIP 的 held-out 与低视角渲染通过。

公开 source archive 含 355 张图；OpenSplat 当前运行使用其中 332 个注册视角。
这两个计数描述的是不同阶段，不能把 archive 图片数误写成训练视角数。

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

`run-status.json=completed` 只表示训练与 PLY 完整写出。本次 held-out 指标、
PLY 健康、保守清理和 OpenSplat 源相机视觉复核均已完成，证据见
[`gfx1100-20260804-summary.json`](../evidence/gfx1100-20260804-summary.json)。
BiGym 内 live 3DGS 合成是另一个 gate，目前因 gsplat 探针退出 `139` 仍为
blocked；不能把 OpenSplat 渲染通过等价为 BiGym 三相机合成通过。
