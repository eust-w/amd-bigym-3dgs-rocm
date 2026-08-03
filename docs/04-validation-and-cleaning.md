# 完整性验收与异常点清理

## LeRobot v3 全量验收

`scripts/validate_lerobot_v3_collection.py` 会验证：

- `meta/info.json` 的 `total_episodes=32`；
- data Parquet 为 32 个、episode metadata 为 32 行；
- `episode_index=0..31` 且 frame index 连续；
- state/action 都是 16 维且没有 NaN/Inf；
- receipt 中 32 个 UUID 唯一、全部 saved、全部 reward=1；
- 三个 camera key 各有 32 个 H.264 视频；
- codec、尺寸、20 fps、帧数、时长和逐帧 decode 全通过；
- 3DGS strict renderer 的渲染计数精确；
- 自动生成 4 episode × 3 camera 联系表和 `SHA256SUMS`。

一个 Parquet chunk 或视频目录看起来“只有一个文件”并不代表只有一个 episode；判断必须以 episode metadata、episode_index 和 row ranges 为准。

## 非破坏式 Gaussian 清理

清理规则同时使用位置、尺度和 alpha：

```text
keep = finite
     & inside_manual_bbox
     & radius <= max_radius
     & exp(max(log_scale)) <= max_world_scale
     & sigmoid(opacity) >= min_alpha
```

输出必须是新路径；脚本发现 output 与 input 相同会直接拒绝。每层生成 JSON manifest，记录输入/输出 SHA-256、Gaussian 数和每种移除原因。

本次保守参数移除 227,279 / 1,000,000 个点，其中 221,336 个是极低 alpha 点。清理后必须重新跑 1 条完整 episode，再用同帧三路视频做 A/B。SSIM 很高不等于更清晰，因此仍需人工看墙面连续性、边缘拉伸、曝光雾块和腕部低视角。
