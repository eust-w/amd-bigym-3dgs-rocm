# AMD Radeon BiGym + 3DGS 厨房环境

[English](README.md) | [中文](README.zh-CN.md) ·
[AMD/ROCm `main`](https://github.com/eust-w/amd-bigym-3dgs-rocm/tree/main)

这是 AMD Radeon/ROCm 主实现，用于重建、加载和校验 BiGym
`DishwasherUnloadCutleryLong` 使用的纯视觉 3D Gaussian Splatting 厨房壳。
下面的重建结果和可下载 shell 均由 AMD Radeon PRO W7900D 生成，
不是从 CUDA 运行复制的产物。

## AMD Radeon 实机复现

![DL3DV 留出原图与 AMD ROCm 15000-step 重建渲染对比](docs/images/amd-rocm-heldout-vs-reference.png)

左侧是 `1920x1080` 留出原图，右侧是 AMD Radeon PRO W7900D 上
OpenSplat/HIP 训练 15,000 steps 的渲染结果。清晰预览门禁以 PSNR
`27.9066`、SSIM `0.9370` 通过；导出 shell 前已去除明显投影拉丝点和
1 个所有相机均不可见的空间离群点。

| AMD 结果 | 已校验值 |
| --- | --- |
| GPU | AMD Radeon PRO W7900D，`gfx1100` |
| 运行时 | PyTorch ROCm/HIP |
| 重建 | 352 张 `1920x1080` 图像，OpenSplat 15,000 steps |
| 清理后结果 | 1,458,354 个 Gaussian |
| 房间壳 | 中央 `3x3m` 工作区净空，新增物理/碰撞为 0 |
| 机器状态 | `amd_rocm_reproduction_passed` |

## 源素材

![DL3DV 商业厨房源轨迹抽样视图](docs/images/canonical-source-contact-sheet.jpg)

该联系表用于溯源。本 README 中的 PLY 下载和 BiGym shell 配置始终
指向下方锁定的 AMD Hugging Face revision。

## AMD 证据边界

| 产物 | 当前结论 |
| --- | --- |
| GitHub `main` | AMD 重建代码、回执和可复现校验 |
| HF revision `amd-rocm-w7900d-20260804` | AMD 清理后 PLY、分层/合并 shell、alignment、profile 和预览 |
| BiGym 采集 | 不由重建回执自动提升；三相机采集是独立验收阶段 |

标准房间重建现在已在 Radeon 上实机复现。但这**不代表**
32 条采集已经在 AMD 上重放：后续采集验收仍要通过原生 gsplat
rasterization、严格三相机回放、全视频解码和独立人工视觉检查。

机器可读状态见
[`evidence/amd-rocm-main-status.json`](evidence/amd-rocm-main-status.json)，
上一个 CUDA 实现单独归档在
[`a800` 分支](https://github.com/eust-w/amd-bigym-3dgs-rocm/tree/a800)，不是本 README 的下载目标。

## 唯一标准输入

| 内容 | 唯一标准 |
| --- | --- |
| AMD 3DGS 房间壳 | [HF revision `amd-rocm-w7900d-20260804`](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell/tree/amd-rocm-w7900d-20260804) |
| DL3DV 来源 | [DL3DV/DL3DV-ALL-2K](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-2K)，revision `e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c` |
| Scene hash | `90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947` |
| AMD 清理后重建 | 1,458,354 个 Gaussian，SHA-256 `d49bcf7219f63a92ee0d40f8d86e618176892ec89853fecc5e217829bff42b9b` |
| AMD 合并 shell | 1,458,255 个 Gaussian，SHA-256 `67ab42e99833749d17db499f4ea1c968b193db26760f567244632f41ae58cb17` |

由于标准素材继续受 DL3DV 和其他上游条款约束，两个 Hugging Face 仓库保持
人工审批下载。

## AMD/ROCm 快速开始

目标环境：

- 能报告 `gfx1100` 的 AMD Radeon GPU；
- AMD Radeon `gfx1100` 上的 ROCm PyTorch；
- 重建使用 OpenSplat commit
  `9fb62fde8b7b8c416121d3cbdcda278ffd9682f7`；
- 下游运行时渲染使用 Python 3.12、MuJoCo 3.10、BiGym 4.1 和
  gsplat 1.4。

先构建 OpenSplat 原生 HIP trainer，下载精确锁定的受控源包，然后运行 AMD
端到端重建：

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

只有回执状态为 `amd_rocm_reproduction_passed` 才算重建通过；精确门禁见
[`reconstruction/README.md`](reconstruction/README.md)。

下载锁定 HF revision 上的 AMD shell，根据
[`evidence/amd-rocm-main-status.json`](evidence/amd-rocm-main-status.json)
核对哈希，然后生成 AMD 运行目录：

```bash
hf auth login
hf download eustance/amd-bigym-3dgs-kitchen-shell \
  --repo-type dataset --revision amd-rocm-w7900d-20260804 \
  --local-dir data/private/amd-rocm-kitchen-shell

export SHELL_WALLS="$PWD/data/private/amd-rocm-kitchen-shell/walls_fixed_kitchen.ply"
export SHELL_FLOOR="$PWD/data/private/amd-rocm-kitchen-shell/floor_perimeter.ply"
export SHELL_CEILING="$PWD/data/private/amd-rocm-kitchen-shell/ceiling_lights.ply"
export SHELL_DIR="$PWD/data/private/amd-runtime-shell"
make stage-shell
```

只有原生 AMD 渲染门禁通过后，才能运行 32 条标准 replay plan：

```bash
export REPLAY_PLAN=/absolute/path/to/cutlery32-replay-plan.json
export DATASET_ROOT=/absolute/path/to/amd-cutlery32
make collect
make validate
```

回放失败必须继续排除；已发布的 AMD 重建回执不会将独立的
32 条回放阶段误标为通过。

## 已实现内容

- 不修改 `/opt/rocm` 的隔离编译器 wrapper；
- 在 `gfx1100` 上锁定 OpenSplat 原生 HIP 重建；
- held-out PSNR/SSIM 与保守的全相机不可见异常点清理；
- `gsplat==1.4.0` `gfx1100` 兼容补丁和真实 rasterization smoke；
- 不增加 MuJoCo 物理对象的 BiGym 纯视觉 shell 合成；
- 禁止 fallback 的 head、左右腕部三相机严格渲染；
- 不同 demonstration 的 replay plan 校验；
- LeRobot v3 结构、有限数值和全视频解码校验；
- CI 使用的无数据许可 CPU 合成重建 smoke。

ROCm 构建边界见 [`docs/02-rocm-gsplat.md`](docs/02-rocm-gsplat.md)，坐标与
合成路径见 [`docs/01-end-to-end.md`](docs/01-end-to-end.md)。

## 仓库校验

```bash
make verify
make smoke-reconstruction
python scripts/check_markdown_links.py
```

GitHub CI 会检查公开文件哈希、JSON 契约、两个补丁、Markdown 链接和无许可依赖
的 shell exporter；真实 Radeon GPU 结果另有机器可读回执和不可变哈希。

## 许可

代码默认采用 Apache-2.0。DL3DV 源数据、派生房间壳、预览和采集画面继续受
CC BY-NC 4.0 与 DL3DV 现行条款约束；BiGym demonstrations 保留上游许可。
