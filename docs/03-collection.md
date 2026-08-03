# 32 条采集与失败回放治理

## 大量回放失败的根因

BiGym 官方 demonstration 不是“取到就一定成功”。源轨迹同时存在 absolute/delta 动作语义，且本次源记录运行时为 BiGym 4.0.0 / MuJoCo 3.1.5，采集运行时为 4.1.0 / 3.10.0。版本、控制频率和动作表示任一漂移，都可能把可播放轨迹变成 `reward=0`。

正式采集采用两阶段 fail-closed 方案：

1. 无相机、无视频、无 3DGS 的物理预检，逐条运行当前 20 Hz runtime。
2. 只把通过原始 task reward 的唯一 UUID 写入 replay plan；正式渲染不再随机选 demo。

delta 源动作会在 `env.step()` 前转换为 absolute 标签，并在第二个 absolute 环境中检查 qpos 误差和最终 reward，从而保证训练集只有一种动作语义。

## 为什么每条 episode 独立落盘

LeRobot v3 默认可能让 metadata 和 Parquet writer 缓存多条记录。容器重启后，视频已经存在，但 Parquet footer 还没有写完。采集补丁做了三件事：

- metadata buffer size 设为 1；
- 每条成功 episode 后关闭 data/meta writer；
- 只有重新加载后可读，才更新 `progress.json`。

发现 0-episode 中断目录时先隔离；发现非空但损坏目录时停止，不回退到 Hub，也不继续拼接。

## 正式门槛

采集 32 条之前，1 条完整冒烟必须同时满足：

- replay 后 `reward=1.0`；
- head、left wrist、right wrist 三路 H.264 可完整解码；
- strict 3DGS 无 fallback、无 `last_error`；
- 渲染次数等于 `(episode frames + reset) × 3`；
- background physics 为 0/0/0。

本次冒烟为 683 帧、2,052 次 3DGS 渲染，全部通过后才启动正式 32 条。
