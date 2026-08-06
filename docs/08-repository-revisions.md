# 阶段、仓库、分支与 commit 台账

更新时间：2026-08-06。

本文件是项目阶段版本关系的唯一规范台账。`源分支` 表示 commit 的上游来源；实际执行必须使用完整 SHA 的 detached HEAD 或等价锁定方式，不能随分支 HEAD 漂移。

## 阶段版本矩阵

| 阶段 | 仓库/资源 | 源分支或 revision | 执行 commit/锁定值 | 角色 |
| --- | --- | --- | --- | --- |
| 全流程编排 | `eust-w/amd-bigym-3dgs-rocm` | `main` | `f66b9150ca7cfd48746147dfa8326a2657ab309e` | 本次审计的运行基线 |
| 文档发布 | `eust-w/amd-bigym-3dgs-rocm` | `docs/pipeline-provenance` | 从 `f66b9150ca7cfd48746147dfa8326a2657ab309e` 创建 | 本次文档与版本治理变更 |
| AMD 3D 重建 | `pierotofy/OpenSplat` | `main` | `9fb62fde8b7b8c416121d3cbdcda278ffd9682f7` | ROCm 重建引擎 |
| AMD 3D 重建 | `DL3DV/DL3DV-ALL-2K` | Hugging Face revision | `e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c` | 输入数据 |
| AMD 3D 重建 | 本项目 OpenSplat patches | 随 `main` 基线 | 两个 `reconstruction/patches/opensplat-*.patch` | ROCm 构建适配 |
| A800 参考重建 | `eust-w/amd-bigym-3dgs-rocm` | `a800` | `b35e318f4dfcfabaaeedd8347c6101384cd7c14d` | CUDA 对照编排 |
| A800 参考重建 | `nerfstudio-project/gsplat` | `main` | `4d3a3b69db4de0326f983ccf7b7b255271a17b01` | CUDA 参考重建/渲染 |
| A800 参考集成 | `discoverse-dev/DISCOVERSE` | `main` | `d67f47c084aba0e0cf422a8725235f8b9238655a` | 参考运行时 |
| 壳发布/导入 | `eustance/amd-bigym-3dgs-kitchen-shell` | Hugging Face revision | `amd-rocm-w7900d-20260804` | Gaussian 壳资产 |
| 壳导入/采集 | `NeuracoreAI/bigym` | `master` | `14beb30318ad14c5d6723175c2ee2281129792af` | BiGym 基线 |
| 壳导入/采集 | 本项目 BiGym overlay | 随 `main` 基线 | `patches/bigym-3dgs-shell-and-collector.patch` | 3DGS、相机与采集接入 |
| 闭环评测 | `WuChao-2024/bigym_plus` | `master` | `d12937686833467b5013ac47a834cf4b6f5a9d53` | 评测客户端基线 |
| OpenDM 外部推理 | `Kyrie-w8/amd-bigym-3dgs-opendm` | `main` | `8f018b253d0fd2b41a4fa4a87610829eaca74c44` | HTTP v2 provider；由 PR `#1` 合并，可作为 OpenDM provider 执行锁 |
| 历史推理实现 | `eust-w/amd-bigym-3dgs-rocm` | `interence` | `eb1bdf844a20f02b2fcb419fa1d33ed4db06484f` | 仅追溯，不是当前主线依赖 |

## 上游贡献分支

这些分支用于把本项目中可独立复用的修改贡献给上游，不是阶段执行版本。实际运行仍以阶段版本矩阵为准。

| fork | 当前分支 | commit | 上游 PR |
| --- | --- | --- | --- |
| `eust-w/bigym_plus` | `upstream/atomic-demo-save` | `2696412ee5064e53ed02d01f0add15f035886abf` | `NeuracoreAI/bigym#61` |
| `eust-w/bigym_plus` | `upstream/demo-recorder-save-state` | `062aa26fd6c19f42d8bb086ffd8130ce92183a00` | `NeuracoreAI/bigym#62` |
| `eust-w/bigym_plus` | `upstream/headless-egl-rendering` | `1eae7b41183789b8db9e25ab61f8849d7c68b75c` | `NeuracoreAI/bigym#63` |
| `eust-w/bigym_plus` | `upstream/lazy-demo-loading` | `f7309da8f9bbd18e4141776e0c8bceb316a9c033` | `NeuracoreAI/bigym#64` |
| `eust-w/bigym_plus` | `upstream/configurable-camera-rendering` | `d665b9536e3155e753d277276c57da51cb2b5086` | `NeuracoreAI/bigym#65` |
| `eust-w/gsplat` | `upstream/rocm-toolkit-probe` | `2e20e3566dd286f59d6df21b0b9364e48e862bc3` | `nerfstudio-project/gsplat#1045` |
| `eust-w/gsplat` | `upstream/rocm-jit-build-flags` | `337427aeccf0e15c5c798cafd0bc2fd84ccd3bb3` | `nerfstudio-project/gsplat#1046` |
| `eust-w/amd-bigym-3dgs-opendm` | `upstream/external-inference-v2` | `394f77f6c321c61e6c3a857728abd651ac09fd13` | `Kyrie-w8/amd-bigym-3dgs-opendm#1` |

## 工作分支

| fork | 当前分支 | commit | 状态 |
| --- | --- | --- | --- |
| `eust-w/bigym_plus` | `work/trajectory-audit-recording` | `da7a86387498a9535a528bd435fc3c6f0a31e735` | 尚未作为独立上游 PR 提交 |
| `eust-w/gsplat` | `work/rocm-gfx1100-runtime` | `223bc85af4f8a8c3de7eac4fa90645cfc02372b0` | 项目工作分支 |
| `eust-w/gsplat` | `work/rocm-jit-toolkit-detection` | `059a82ce84952447ff193ddf828fc772f663b083` | 项目工作分支 |

## `agent/*` 分支改名记录

GitHub 不会在跨仓库 PR 中自动迁移已改名的 head ref。为保持 commit 不变并去除 `agent/` 前缀，旧 PR 已关闭，并以相同 commit 创建新的 Ready PR。

| 仓库 | 旧分支/PR | 新分支/PR | commit |
| --- | --- | --- | --- |
| `eust-w/bigym_plus` | `agent/atomic-demo-save`, BiGym `#56` | `upstream/atomic-demo-save`, BiGym `#61` | `2696412ee5064e53ed02d01f0add15f035886abf` |
| `eust-w/bigym_plus` | `agent/demo-recorder-save-state`, BiGym `#57` | `upstream/demo-recorder-save-state`, BiGym `#62` | `062aa26fd6c19f42d8bb086ffd8130ce92183a00` |
| `eust-w/bigym_plus` | `agent/headless-egl-rendering`, BiGym `#58` | `upstream/headless-egl-rendering`, BiGym `#63` | `1eae7b41183789b8db9e25ab61f8849d7c68b75c` |
| `eust-w/bigym_plus` | `agent/lazy-demo-loading`, BiGym `#59` | `upstream/lazy-demo-loading`, BiGym `#64` | `f7309da8f9bbd18e4141776e0c8bceb316a9c033` |
| `eust-w/bigym_plus` | `agent/configurable-camera-rendering`, BiGym `#60` | `upstream/configurable-camera-rendering`, BiGym `#65` | `d665b9536e3155e753d277276c57da51cb2b5086` |
| `eust-w/bigym_plus` | `agent/trajectory-audit-recording` | `work/trajectory-audit-recording` | `da7a86387498a9535a528bd435fc3c6f0a31e735` |
| `eust-w/gsplat` | `agent/rocm-toolkit-probe-upstream`, gsplat `#1043` | `upstream/rocm-toolkit-probe`, gsplat `#1045` | `2e20e3566dd286f59d6df21b0b9364e48e862bc3` |
| `eust-w/gsplat` | `agent/rocm-jit-build-flags`, gsplat `#1044` | `upstream/rocm-jit-build-flags`, gsplat `#1046` | `337427aeccf0e15c5c798cafd0bc2fd84ccd3bb3` |
| `eust-w/gsplat` | `agent/rocm-gfx1100-runtime` | `work/rocm-gfx1100-runtime` | `223bc85af4f8a8c3de7eac4fa90645cfc02372b0` |
| `eust-w/gsplat` | `agent/rocm-jit-toolkit-detection` | `work/rocm-jit-toolkit-detection` | `059a82ce84952447ff193ddf828fc772f663b083` |

当前编排仓库的六个历史本地分支也已由 `agent/*` 改为 `archive/*`；它们未推送到远端，故不作为可复现依赖列入阶段矩阵。远端 `eust-w/amd-bigym-3dgs-rocm` 本来就没有有效的 `agent/*` 分支；本地过期的 `origin/agent/full-evaluation-recording` tracking ref 已清理。

## 版本更新流程

1. 先更新本台账的完整 SHA，再更新阶段文档中的摘要。
2. 在证据收据中记录执行时的 `git remote get-url origin`、`git branch --show-current` 和 `git rev-parse HEAD`。
3. 上游分支 HEAD 变化时不得静默移动执行锁；必须重新运行对应阶段验收。
4. 评测 provider 不进入固定矩阵时，必须在单次评测收据中补齐相同字段。
