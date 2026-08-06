# 证据与当前状态

本项目把“代码存在”“任务启动”“产物可解析”“视觉通过”“完整采集”“闭环成功”视为不同证据层级。

## 证据层级

| 层级 | 能证明什么 | 不能证明什么 |
| --- | --- | --- |
| 代码/配置 | 路径和参数已实现 | 实际运行成功 |
| 进程/日志 | 任务启动并执行到某处 | 最终产物完整 |
| 产物完整性 | 文件可解析、属性和哈希有效 | 视觉质量可接受 |
| 视觉证据 | 指定相机或自由视角画面可检查 | 物理、采集或策略成功 |
| 轨迹证据 | transition、帧和动作连续 | 任务达到 success |
| 评测收据 | provider、模型、代码、指标可追溯 | 未记录字段的外部状态 |

## 仓库内证据入口

- AMD 主线状态：`evidence/amd-rocm-main-status.json`。
- A800 参考摘要：`evidence/a800-reference-validation-summary.json`。
- 评测/采集证据规范：`evaluation/bigym-3dgs/evidence/README.md`。
- 图片材料说明：[images/README.md](images/README.md)。
- 视频材料说明：[videos/README.md](videos/README.md)。

## 当前可确认结论

- AMD 主线锁定了 OpenSplat commit、DL3DV revision 和已发布壳 revision。
- 壳导入采用视觉壳与 MuJoCo 物理解耦设计，并有明确的 Sim(3) 对齐边界。
- BiGym 采集设计要求官方 demo、原子 episode、完整 transition 和失败隔离。
- 闭环评测协议要求真实 policy request、连续动作执行、完整轨迹和 provider 收据。
- BiGym 与 gsplat 的可上游复用修改已使用无 `agent/` 前缀的分支重新提交 Ready PR。

## 尚不能确认的结论

- 没有统一的连续遥测，不能给出所有阶段可靠的 GPU 使用率和显存占用率。
- 不能仅凭 PLY 存在声称自由视角视觉质量通过。
- 不能仅凭 smoke 回放声称目标数量的正式成功采集完成。
- `main` 没有可接受的正式策略闭环收据，不能声称闭环评测完成。
- A800 参考结果不能替代 AMD ROCm 主线路径验收。

## 后续证据最低要求

| 阶段 | 必须新增的证据 |
| --- | --- |
| 重建 | ROCm 设备信息、连续 GPU/VRAM 遥测、训练日志、最终 PLY 哈希、训练与自由视角渲染 |
| 壳导入 | Sim(3) 配置、多相机静态图和运动视频、前后景遮挡、物理碰撞回归 |
| 采集 | LeRobot v3 元数据、episode 索引、transition 范围、成功/失败清单、视频帧对齐 |
| 评测 | provider `/health`、模型和代码 revision、每步请求/动作、终止原因、成功率与 GPU 时序 |

