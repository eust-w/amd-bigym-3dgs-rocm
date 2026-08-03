[🇺🇸 English](06-gfx1100-execution-report.md) | [🇨🇳 中文](06-gfx1100-execution-report.zh-CN.md)

# AMD gfx1100 实测执行报告（2026-08-04）

本文记录 Radeon 原生 3DGS 重建、人工 Gaussian 清理、任务感知房间壳导出、
BiGym 运行探针，以及一条独立 `DishwasherUnloadCutleryLong` 采集 smoke 的实测
状态。重建画质、房间壳渲染、BiGym 实时合成和数据采集是四个独立 gate，不能
互相替代。

机器可读证据见
[`evidence/gfx1100-20260804-summary.json`](../evidence/gfx1100-20260804-summary.json)。

## 结论总览

| Gate | 结果 | 核验证据 |
| --- | --- | --- |
| OpenSplat HIP 30k 重建 | **通过** | PSNR `33.8326`、SSIM `0.971857`、LPIPS `0.038427` |
| 保守人工清理 | **通过** | 删除 177 个明显空间离群点，原始 PLY 保留 |
| CutleryLong 三层房间壳 | **通过** | 991,213 Gaussian，中央工作区违规点为 0 |
| OpenSplat 原生房间壳渲染 | **通过** | held-out 与低视角源相机画面通过 |
| 原生 BiGym/MuJoCo smoke | **通过** | 32 帧、三相机、无 termination |
| BiGym 内实时 3DGS 合成 | **阻塞** | gsplat 严格探针以 `139` 退出 |
| 独立原生 CutleryLong 单条数据 | **通过** | 683 帧、三路 H.264、回执 reward `1.0` |
| 带 3DGS 壳的数据采集 | **未运行** | 被实时合成 gate 阻塞 |

## 1. 原始数据与 AMD 原生重建

本次使用 [DL3DV-ALL-960P](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-960P)
场景 `951f9db189a7023708b7798e147e04048a84ce039c5761e8ecb1aa65dcb2da86`，
固定 revision 为 `abb4dab0d4b6d93c32e6d901c06c35bad03210fb`。OpenSplat 在
332 个注册视角中使用 331 个训练视角，并把 `frame_00159.png` 留作 held-out。
训练运行在 AMD Radeon PRO W7900D（`gfx1100`）上，OpenSplat commit 为
`9fb62fde8b7b8c416121d3cbdcda278ffd9682f7`，步数为 30,000。

最终 PLY 含 1,198,821 个 Gaussian，大小 297,309,190 bytes，SHA-256 为
`208cbbb9c69c6319e42da2828b37ac816556b6acb48828164507ca82d302b57d`。

## 2. 人工清理与 A/B 复核

清理过程始终写入副本，不覆盖权威 PLY。最终接受的规则只删除 177 个空间
离群点。另一个“大尺度 Gaussian”规则命中 79 个点，但 held-out 画面出现明显
紫色地面残留，因此被否决。visual-safe 副本保留 1,198,644 个 Gaussian，
SHA-256 为
`a1fb19bbb45f4dcf0f39fbc2ad38230a592409fd8acf51af78f530f4a5d10a7a`。

![held-out 原始与 visual-safe A/B](images/gfx1100/reconstruction-ab-heldout.png)

![低视角原始与 visual-safe A/B](images/gfx1100/reconstruction-ab-low-view.png)

![人工清理动态复核](images/gfx1100/reconstruction-cleaning-review.gif)

## 3. CutleryLong 任务感知房间壳

导出器直接测量 MuJoCo 任务几何，而不是假设工作区位于原点。原始任务工作区
中心为 `[0.4934, -0.6228]` m，范围为 1.8365 m × 2.5988 m，净高 2.4 m。
加入安全边距后，房间壳保留 visual-safe 重建的 82.6945%，受保护工作区内可见
Gaussian 违规点为 0。

三层分别为：墙面/装饰 886,194、周边地面 13,909、顶面/灯具 91,110；组合壳
共 991,213 个 Gaussian，SHA-256 为
`c277948cf584397e8fc7a7524df61fe845718d200491ea4ffa39345d98e9d50f`。

| held-out 视角 | 低视角 |
| --- | --- |
| ![房间壳 held-out 视角](images/gfx1100/shell-native-heldout.png) | ![房间壳低视角](images/gfx1100/shell-native-low-view.png) |

## 4. BiGym 运行边界

原生 `DishwasherUnloadCutleryLong` 已在 16 维动作空间下运行 32 帧，三路 RGB
相机契约正确，最大接触数为 3，未发生 termination。下图是原生 BiGym 程序化
环境，**不代表已经叠加 3DGS 背景**。

| 原生初始帧 | 原生结束帧 |
| --- | --- |
| ![原生 BiGym 初始帧](images/gfx1100/bigym-native-initial.png) | ![原生 BiGym 结束帧](images/gfx1100/bigym-native-final.png) |

预编译 ROCm gsplat 扩展可以导入并暴露所需符号，但真正的带壳 BiGym 探针进入
渲染路径后以 `139` 退出。因此实时合成状态为 **blocked**，正式房间壳验收
**未通过**，不能把后续数据写成“带 3DGS 壳采集完成”。

## 5. 独立单条采集

隔离输出目录新增了 1 条原生 BiGym 成功轨迹，没有触碰保留的 32 条归档。该条
数据含 683 帧、1 个 Parquet 数据文件和 3 个 H.264 视频；视频总计
16,596,729 bytes。`reward=1.0` 来自 `run-receipt.json`，不声称 Parquet 内存在
reward 列。真实 demonstration UUID 与视频继续保存在授权 artifact store，不在
公共仓库分发。

历史 32 条 A800-parity 归档仍为 484,207,348 bytes，保持不变；它不是本次
gfx1100 实时 3DGS 链路的产物。

## 6. 下一工程 gate

下一步应构造最小 `fully_fused_projection` 复现，按当前运行时的 Torch/HIP ABI
重编 gsplat，再重跑 strict 三相机房间壳探针。只有三相机合成画面无 fallback
通过后，才能启动 32 条带壳采集。
