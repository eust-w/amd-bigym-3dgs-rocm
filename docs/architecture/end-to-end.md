# End-to-end architecture

```mermaid
flowchart TB
  subgraph Data[Data plane]
    D1[Authorized DL3DV archive]
    D2[Official BiGym demonstrations]
    D3[Public manifests and synthetic fixture]
  end

  subgraph Reconstruction[Reconstruction plane]
    R1[Safe extraction]
    R2[Known-pose COLMAP + SIFT]
    R3[OpenSplat HIP 30k on gfx1100]
    R4[Quality-gated Graphdeco PLY]
    R5[Sim3 and room-layer export]
  end

  subgraph Runtime[AMD ROCm runtime plane]
    A1{ROCm gsplat live-compositor gate}
    A2[Gaussian background render]
    A3[MuJoCo segmentation foreground]
  end

  subgraph Collection[Dataset plane]
    C1[20 Hz reward precheck]
    C2[32 unique replay UUIDs]
    C3[LeRobot v3 + 96 videos]
    C4[Hash, decode and visual acceptance]
  end

  D1 --> R1 --> R2 --> R3 --> R4 --> R5
  R5 --> A1
  A1 -. current gfx1100 exit 139 .-> A2 --> A3
  D2 --> C1 --> C2
  A3 --> C3
  C2 --> C3 --> C4
  D3 -. CI contract .-> R5
```

The planes are deliberately separate. A valid PLY does not prove BiGym
integration; a successful GPU render does not prove dataset reward; and a fully
decoded dataset does not prove photographic quality. Each boundary emits a
machine-readable receipt.

As of 2026-08-04, the gfx1100 reconstruction and native OpenSplat shell renders
pass, while the live gsplat compositor gate is blocked. Native BiGym and a
single independent episode can be tested without crossing that gate, but they
must be labelled native-only and must not be presented as shell-backed data.
