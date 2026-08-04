# ROCm 重建与渲染说明

## 为什么 AMD 重建使用 OpenSplat

本仓库把“训练重建”和“BiGym 运行时渲染”分成两个独立门禁：

| 阶段 | AMD 实现 | 验收方式 |
| --- | --- | --- |
| DL3DV 训练与 PLY 导出 | OpenSplat 原生 HIP backend | W7900D 实机训练、held-out 渲染、PLY 结构与异常点校验 |
| BiGym 三相机渲染 | `gsplat==1.4.0` 的 `gfx1100` 适配 | 原生 rasterization smoke、三相机严格模式、禁止 fallback |

项目锁定的 AMD gsplat 代码在 W7900D 的 wave32 目标上会触发 rocPRIM
wave64 静态断言；官方预编译 wheel 也不包含 `gfx1100` code object。因此，
重建入口使用已经在相同硬件上编译、执行和导出 PLY 的 OpenSplat HIP backend，
不把“能 import”或失败的 gsplat 编译当作重建完成。

## AMD 重建锁定环境

| 组件 | 实机值 |
| --- | --- |
| GPU | AMD Radeon PRO W7900D，`gfx1100`，48GB |
| PyTorch | `2.8.0+rocm7.13.0a20260513` |
| HIP | `7.13.26183-83e9908b71` |
| OpenSplat | commit `9fb62fde8b7b8c416121d3cbdcda278ffd9682f7` |
| 输入 | 352 张 `1920×1080` DL3DV 商业厨房图片 |
| 默认训练 | 15,000 steps，单张 held-out 验证 |

`reconstruction/bin/reconstruct_rocm.sh` 会依次执行：

1. 锁定源包 revision、字节数、SHA-256 与 ZIP CRC；
2. 运行真实 AMD/HIP 张量探针；
3. 通过已知位姿 SIFT 三角化构造 COLMAP 初始化；
4. 调用 OpenSplat HIP 训练并输出 held-out 渲染；
5. 归一化 OpenSplat 四元数，删除鲁棒半径外且所有相机均不可见的异常点，以及明显高 alpha 投影拉丝点；
6. 重新校验清理后的 PLY 并导出中央净空、零碰撞的四层房间壳；
7. 写出 `amd-rocm-reproduction.json`。

## gsplat 运行时门禁

`patches/gsplat-1.4.0-rocm-gfx1100.patch` 与隔离编译器 wrapper 仍用于
BiGym 的实时三相机 Gaussian rasterization。它不会修改 `/opt/rocm`，
JIT cache 也放在独立的 `TORCH_EXTENSIONS_DIR`。

`import gsplat` 不算通过；`scripts/smoke_test_gsplat.py` 必须真正执行
rasterization、GPU 同步，并验证 RGB/alpha shape 与有限值。重建回执和运行时
渲染回执不能互相替代。
