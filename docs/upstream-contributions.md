# 上游贡献

本项目把与 AMD/BiGym 交付无关的通用改进拆成小型上游 PR。所有现行分支均已移除 `agent/` 前缀，PR 状态于 2026-08-06 核验为 open、Ready、mergeable。

## BiGym

| PR | 分支 | commit | 修改 | 本地定向测试 |
| --- | --- | --- | --- | --- |
| [NeuracoreAI/bigym#61](https://github.com/NeuracoreAI/bigym/pull/61) | `upstream/atomic-demo-save` | `2696412ee5064e53ed02d01f0add15f035886abf` | demo 原子保存 | 2 passed |
| [NeuracoreAI/bigym#62](https://github.com/NeuracoreAI/bigym/pull/62) | `upstream/demo-recorder-save-state` | `062aa26fd6c19f42d8bb086ffd8130ce92183a00` | recorder save state | 2 passed |
| [NeuracoreAI/bigym#63](https://github.com/NeuracoreAI/bigym/pull/63) | `upstream/headless-egl-rendering` | `1eae7b41183789b8db9e25ab61f8849d7c68b75c` | headless EGL 渲染 | 4 passed |
| [NeuracoreAI/bigym#64](https://github.com/NeuracoreAI/bigym/pull/64) | `upstream/lazy-demo-loading` | `f7309da8f9bbd18e4141776e0c8bceb316a9c033` | demo 延迟加载 | 13 passed |
| [NeuracoreAI/bigym#65](https://github.com/NeuracoreAI/bigym/pull/65) | `upstream/configurable-camera-rendering` | `d665b9536e3155e753d277276c57da51cb2b5086` | 可配置相机 FOV 和 framebuffer | 12 passed |

旧 PR `#56-#60` 因 GitHub 跨仓库 head 分支改名而自动关闭。`#61-#65` 使用相同 commit，是当前唯一有效入口。

## gsplat

| PR | 分支 | commit | 修改 | 本地定向测试 |
| --- | --- | --- | --- | --- |
| [nerfstudio-project/gsplat#1045](https://github.com/nerfstudio-project/gsplat/pull/1045) | `upstream/rocm-toolkit-probe` | `2e20e3566dd286f59d6df21b0b9364e48e862bc3` | ROCm toolkit 探测 | 4 passed |
| [nerfstudio-project/gsplat#1046](https://github.com/nerfstudio-project/gsplat/pull/1046) | `upstream/rocm-jit-build-flags` | `337427aeccf0e15c5c798cafd0bc2fd84ccd3bb3` | ROCm JIT 构建 flags | 5 passed |

旧 PR `#1043-#1044` 因相同的分支改名限制而关闭。`#1045-#1046` 保持原 commit，并作为当前 Ready PR。

## 未作为上游 PR 的工作分支

- `eust-w/bigym_plus:work/trajectory-audit-recording@da7a86387498a9535a528bd435fc3c6f0a31e735`
- `eust-w/gsplat:work/rocm-gfx1100-runtime@223bc85af4f8a8c3de7eac4fa90645cfc02372b0`
- `eust-w/gsplat:work/rocm-jit-toolkit-detection@059a82ce84952447ff193ddf828fc772f663b083`

完整分支改名映射和阶段依赖见 [阶段、仓库、分支与 commit 台账](08-repository-revisions.md)。
