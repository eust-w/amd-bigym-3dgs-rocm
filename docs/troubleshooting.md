# 常见故障

## `torch.version.hip is None`

安装的是 CUDA/CPU PyTorch，不是 ROCm build。回到 AMD 官方兼容矩阵安装，不要继续编 gsplat。

## `hipcc` 存在但 JIT 仍寻找 `nvcc`

确认 `ROCM_HOME` 指向本仓库创建的 wrapper，`PATH` 中 wrapper/bin 位于前面，并重新设置一个空的 `TORCH_EXTENSIONS_DIR`。

## rocThrust / BF16 重复定义

通常是 ROCm 系统头被 hipify 处理过，或 include 顺序混入了复制头。重新安装/校验官方 `hip-dev`、`rocthrust-dev`，只在独立 wrapper 和虚拟环境中重建。不要编辑 `/opt/rocm/include`。

## GLM 出现 HIP 化后的奇怪符号

不要把 GLM 作为 PyTorch JIT 的 `extra_include_paths`。本仓库补丁移除了该路径，并用 `CPLUS_INCLUDE_PATH` 指向 gsplat 原始 GLM tree。

## 采集大量 `reward=0`

停止正式渲染，重新运行 20 Hz physics-only verifier。检查 demo 的 absolute/delta 表示、BiGym/MuJoCo 版本和 seed；失败轨迹不得写入成功训练集。

## “只有一个 episode”

不要按目录里的 chunk 数判断。读取 `meta/episodes`、data Parquet 的 `episode_index`、行范围和 `meta/info.json`。本仓库验证器按这些字段给出结论。

## 能运行但看不到房间壳

依次确认：profile 指向存在的 PLY；`T_gaussian_to_mujoco` 非单位占位矩阵；相机位于捕获路径附近；strict receipt 中 enabled=true、last_error=null、render count 大于 0。测试数量不能替代解码后的多相机画面。

## 壳能看到但低视角模糊/拉伸

这通常是源相机覆盖问题，不是继续删点可以解决。低 alpha/超大尺度/远处点可以保守清理；要达到照片级低视角，需要补拍覆盖 H1 头部与腕部姿态的源图并重新训练。
