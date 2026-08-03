# 端到端实现与坐标系

## 为什么把 3DGS 做成“视觉壳”

MuJoCo 擅长稳定、可验证的机器人与物体物理；3DGS 擅长真实环境外观。把两者拆开后，环境背景不进入 MJCF，因而不会影响碰撞、接触、reward 或控制轨迹。

每个相机帧的处理顺序是：

1. 从 MuJoCo 取得相机外参、内参、RGB 和 segmentation。
2. 用 `T_gaussian_to_mujoco` 的逆变换把 MuJoCo 相机转换到 Gaussian 坐标系。
3. gsplat 在 AMD GPU 上渲染背景。
4. 依据 segmentation 把机器人、工作台、任务物体覆盖回背景。
5. strict 模式记录渲染次数和最后错误；任意 3DGS 错误直接终止正式采集。

## Sim(3) 对齐

配置中的 4×4 变换把 Gaussian 世界映射到 MuJoCo 世界：

```text
p_mujoco = s R p_gaussian + t
```

这里不仅要“看起来对齐”，还需要独立检查：

- 地面法向保持竖直；
- 房间高度和相对尺度在合理范围；
- head / left wrist / right wrist 相机距离训练相机轨迹不过远；
- 旋转偏差不过大；
- floor 高度不因外观搜索而改变。

本次外观搜索只调水平平移与 yaw，最终再选择完整 H1 可见的固定 external 相机。实测 profile 保存在 `configs/`，其中也保留了视觉质量边界。

## 物理隔离验收

收据必须记录：

```json
{
  "background_physics": {
    "body_count": 0,
    "geom_count": 0,
    "collision_count": 0
  }
}
```

这三个数字只能证明 3DGS 没有进入物理世界，不能替代视觉验收。
