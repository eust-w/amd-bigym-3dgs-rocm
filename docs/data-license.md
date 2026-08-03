# 数据与许可边界

## 本仓库包含什么

- Apache-2.0 的授权下载门禁、COLMAP 准备、A800 重建、三层壳导出、
  编排、验证和清理脚本；
- 对 BiGym / gsplat 的源码补丁；
- `data/manifests/` 中不含原图和真实 UUID 的数据契约；
- CI 运行时生成的 Apache-2.0 合成 Gaussian 房间；
- 不含 demo UUID 的 replay plan schema；
- 脱敏的机器统计与小尺寸人工验收联系表；联系表是经过 3DGS 重建、
  MuJoCo 合成、缩放和标注的研究结果，单独按 CC BY-NC 4.0 与 DL3DV
  Terms of Use 标注，见 `docs/images/README.md`；
- 对齐矩阵和视觉壳 profile 元数据。

## 本仓库不包含什么

- DL3DV 原始图片或视频；
- DL3DV 派生的完整 PLY；
- BiGym official demonstrations 或其真实 UUID 列表；
- LeRobot 32 条完整训练包；
- SSH 地址、端口、密钥、云实例或私有对象存储地址。

因此 public repo 能完整复现处理逻辑，但需要使用者自行取得合法输入；
`make smoke-reconstruction` 只使用合成数据验证代码结构。

## DL3DV

本次房间壳来源记录为 DL3DV-10K scene hash `951f9db189a7023708b7798e147e04048a84ce039c5761e8ecb1aa65dcb2da86`、revision `abb4dab0d4b6d93c32e6d901c06c35bad03210fb`。使用者需要在 [DL3DV-10K 官方仓库](https://github.com/DL3DV-10K/Dataset) 申请访问、阅读并接受最新 Terms of Use 和 license。

本次历史记录把该来源标记为非商业研究用途。官方条款还限制原始 Dataset 的转交：接收者需要自行同意条款。许可可能更新，使用者应以下载时的官方条款为准。不要把本仓库的 Apache-2.0 误读为对数据、派生 PLY 或 `docs/images/` 的授权。

## BiGym demonstrations

官方仓库明确提示并非所有 demonstration 都能成功完成任务。请按其分发渠道和许可取得数据；本仓库只提供本地验证与筛选逻辑，不再分发轨迹或真实 UUID。
