# BiGym + DL3DV 3DGS 标准厨房数据

[English](README.md) | [中文](README.zh-CN.md)

本仓库保存唯一标准采集包对应的代码、配置和公开数据契约。当前分支所有
配置、manifest 和文档只允许指向下面这一组数据与房间壳：

- 数据：`bigym-3dgs-light-floor-replay-plan-v2-20260802/dishwasher_unload_cutlery_long`；
- 房间壳：DL3DV 商用厨房场景
  `90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947`。

所有已废弃的场景和采集身份均已从当前分支移除。

## 标准发布地址

| 内容 | 唯一标准 |
| --- | --- |
| LeRobot v3 数据 | [eustance/openSource_AMD_AI_DevMaster_Hackathon_202608](https://huggingface.co/datasets/eustance/openSource_AMD_AI_DevMaster_Hackathon_202608) |
| 数据路径 | `bigym-3dgs-light-floor-replay-plan-v2-20260802/dishwasher_unload_cutlery_long` |
| 3DGS 房间壳 | [eustance/amd-bigym-3dgs-kitchen-shell](https://huggingface.co/datasets/eustance/amd-bigym-3dgs-kitchen-shell) |
| 上游来源 | [DL3DV/DL3DV-ALL-2K](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-2K)，revision `e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c` |
| 采集运行环境 | NVIDIA A800 / CUDA |
| 视觉状态 | `awaiting_visual_approval` |

由于 DL3DV 的现行条款和非商业限制，两个 Hugging Face 仓库均为人工审批下载。

## 数据验收结果

- 任务：`DishwasherUnloadCutleryLong`；
- 32 条不同且保存时 `reward=1.0` 的 episode，索引 `0..31`；
- 共 21,018 帧，20 fps；
- state/action 均为 16 维有限 `float32`；
- 一个合并后的数据 Parquet、一个包含 32 行的 episode 元数据 Parquet；
- 三个合并后的 H.264 视频：`cam_high`、`cam_left_wrist`、`cam_right_wrist`；
- 三个视频均为 21,018 帧，并已通过完整解码。

这份数据通过了结构和技术校验，但尚未取得人工视觉验收，不应写成“视觉合格的
正式训练集”。精确文件哈希见
[`data/manifests/cutlery32-dataset.public.json`](data/manifests/cutlery32-dataset.public.json)。

## 房间壳验收结果

标准房间壳使用 gsplat MCMC scheduled-r20，训练 60,000 step，seed 42，
Gaussian 上限 2,000,000。合并后的壳包含 862,104 个 Gaussian：

```text
gaussians_shell.ply
SHA-256 086f1f5757523db94349de16707806e74a65bac35b24d9e4e7437639164738a7
```

墙、地面、顶灯、合并壳和 alignment 的精确哈希见
[`data/manifests/a800-reconstruction.public.json`](data/manifests/a800-reconstruction.public.json)。
PLY 和 alignment 与采集回执逐字节一致。发布的 profile 是根据保留下来的校准
profile 和相同浅色公制地面参数重新生成的，语义一致，但不应声称与已丢失的
A800 临时 profile 逐字节相同。

## 下载

先使用已获两个受控仓库权限的 Hugging Face 账号登录：

```bash
hf auth login
hf download eustance/amd-bigym-3dgs-kitchen-shell \
  --repo-type dataset --local-dir data/private/canonical-shell
hf download eustance/openSource_AMD_AI_DevMaster_Hackathon_202608 \
  --repo-type dataset \
  --include 'bigym-3dgs-light-floor-replay-plan-v2-20260802/**' \
  --local-dir data/private/canonical-cutlery32
```

训练或评测前请用两个公开 manifest 对下载文件做 SHA-256 校验。

## 关键代码

- [`reconstruction/`](reconstruction/README.md)：授权下载、重建、导出和校验；
- [`configs/dl3dv-kitchen-cutlery32-profile.json`](configs/dl3dv-kitchen-cutlery32-profile.json)：
  唯一标准 profile；
- [`scripts/run_cutlery32.sh`](scripts/run_cutlery32.sh)：正式采集入口；
- [`scripts/validate_lerobot_v3_collection.py`](scripts/validate_lerobot_v3_collection.py)：
  LeRobot 结构和完整视频校验；
- [`docs/data-license.md`](docs/data-license.md)：许可和再分发边界。

AMD ROCm 脚本仍作为同一工作负载的移植路径保留，但不会改变 A800 采集数据和
房间壳的唯一身份。

## 本地校验

```bash
make verify
make smoke-reconstruction
```

Git 仓不保存源 ZIP、完整 PLY 或完整采集包；它们只存放在人工审批的 Hugging
Face 仓库中。

## 许可

代码默认采用 Apache-2.0。DL3DV 源数据、派生房间壳、预览和采集画面继续受
CC BY-NC 4.0 与 DL3DV 现行条款约束；BiGym demonstrations 保留上游许可。
