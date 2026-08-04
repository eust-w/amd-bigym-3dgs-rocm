# 数据与许可边界

本仓库的 Apache-2.0 只覆盖项目自身代码，不会扩大上游数据和派生资产的许可。

唯一标准房间壳来源是 `DL3DV/DL3DV-ALL-2K` 的商业厨房场景：

- scene hash：`90e70328f9196bc78c7e6c695c1e8cbb55a3c961cccf34c566966a5e2d8d8947`；
- revision：`e035bc5efd8dc5b2fa1e704cb2b1086fd9ec2c5c`；
- object：`4K/90e70328...zip`；
- archive SHA-256：`9765ce6dd3661ba125b6689c0cc50717645480ec2ce5790a4636129521341adb`。

DL3DV 当前许可用于非商业研究与教育，并对数据共享设置了额外条款。每位使用者
都应从[官方数据页](https://huggingface.co/datasets/DL3DV/DL3DV-ALL-2K)
独立申请访问并接受最新条款。因此完整派生 PLY 和带有 DL3DV 画面的 LeRobot
数据只放在人工审批的 Hugging Face 仓库，不提交到 Git。

唯一标准采集数据为
`bigym-3dgs-light-floor-replay-plan-v2-20260802/dishwasher_unload_cutlery_long`。
其中包含 BiGym demonstration 的回放结果，使用者还需遵守 BiGym 与
demonstration 各自的上游许可。

本仓库包含的 manifest、对齐参数和代码不能被解释为对 DL3DV 原始数据、派生
PLY、预览或采集帧授予商业使用权。许可可能更新，实际使用应以下载时的官方条款
为准。
