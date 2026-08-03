# ROCm / gsplat 适配说明

## 实测环境

| 组件 | 版本 |
| --- | --- |
| GPU 架构 | `gfx1100` |
| ROCm | 7.2.1 |
| PyTorch | `2.9.1+gitff65f5b` |
| HIP runtime | `7.2.53211-e1a6bc5663` |
| Python | 3.12 |
| gsplat | 1.4.0 |

AMD 官方当前建议优先使用经过验证的 PyTorch 容器或对应 wheel。请先按 [官方 Radeon PyTorch 文档](https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/install/installrad/native_linux/install-pytorch.html) 建好基础环境，再运行本仓库补丁。

## 补丁解决的问题

`patches/gsplat-1.4.0-rocm-gfx1100.patch` 是从实测 site-packages 与原始 1.4.0 wheel 精确比较得到的：

- 让 backend 在 `ROCM_HOME` + `hipcc` 下进入 JIT 编译；
- 为 clang/HIP 设置 wave32 与兼容宏；
- 避免把 GLM 目录作为 hipify 的额外 include 路径；
- 修正 HIP 对 `cudaFuncSetAttribute` kernel 指针类型的要求；
- 在 HIP 下把 CUB 映射到 hipCUB；
- 为 cooperative groups 补充 reduce 和 labeled partition 语义；
- 替换 ROCm clang 无法解析的部分 GLM 数学调用。

## 为什么使用隔离 wrapper

直接改 `/opt/rocm` 容易让 PyTorch hipify 污染系统头文件。脚本只创建一个很薄的编译器入口：

```text
ROCM_WRAPPER/
├── bin/hipcc       -> 调用 ROCm clang++
├── include         -> /opt/rocm-7.2.1/include
└── lib             -> /opt/rocm-7.2.1/lib
```

系统 `hip-dev`、`rocthrust-dev` 保持原样，JIT cache 放到独立 `TORCH_EXTENSIONS_DIR`。

## 预编译扩展的隔离加载

当扩展已经由与运行时一致的 Torch/HIP 环境编译完成时，可以把
`scripts/rocm_gsplat_sitecustomize.py` 复制为隔离目录下的 `sitecustomize.py`，
并通过 `BIGYM_GSPLAT_PREBUILT_DIR` 指向扩展目录。这个入口只绕过 gsplat 的
CUDA toolkit 探测，不修改安装包：

```bash
mkdir -p /tmp/gsplat-bootstrap
cp scripts/rocm_gsplat_sitecustomize.py /tmp/gsplat-bootstrap/sitecustomize.py
export PYTHONPATH=/tmp/gsplat-bootstrap:$PYTHONPATH
export BIGYM_GSPLAT_PREBUILT_DIR=/path/to/torch_extensions/gsplat_cuda
python -c 'from gsplat.cuda._backend import _C; print(_C)'
```

## 通过标准与当前结果

`import gsplat` 不够。`scripts/smoke_test_gsplat.py` 会真正调用 rasterization、同步 GPU，并检查 RGB/alpha 的 shape 与有限值。只有出现以下结果才算 native gate 通过：

```text
GATE_OK True
TORCH 2.9.1+... HIP 7.2...
DEVICE AMD Radeon ...
```

2026-08-04 的 W7900D 实测中，预编译扩展可以导入并暴露 projection 与
rasterization 符号，但严格的 BiGym 三相机房间壳探针在真实渲染路径中以
`139` 段错误退出。因此当前状态是
`blocked_gsplat_projection_segfault`，不是 `GATE_OK True`。原生 BiGym smoke
和 OpenSplat HIP 的源相机房间壳渲染分别通过，但不能替代这个 gate。

下一步应先用最小 `fully_fused_projection` 输入复现故障，确认扩展与
PyTorch `2.9.1+gitff65f5b` / HIP `7.2.53211-e1a6bc5663` 的 ABI 一致，重新构建
后再运行 strict 三相机合成。详见
[gfx1100 execution report](06-gfx1100-execution-report.md)。
