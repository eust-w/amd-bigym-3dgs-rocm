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

## 通过标准

`import gsplat` 不够。`scripts/smoke_test_gsplat.py` 会真正调用 rasterization、同步 GPU，并检查 RGB/alpha 的 shape 与有限值。只有出现以下结果才算 native gate 通过：

```text
GATE_OK True
TORCH 2.9.1+... HIP 7.2...
DEVICE AMD Radeon ...
```
