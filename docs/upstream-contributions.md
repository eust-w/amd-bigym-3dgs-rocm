# Contributions proposed to canonical BiGym

Reusable simulator improvements are proposed directly to
[`NeuracoreAI/bigym`](https://github.com/NeuracoreAI/bigym). Provider-specific
model runtime and checkpoint code stay outside the default integration branch;
the former reference provider is archived on the
[`interence`](https://github.com/eust-w/amd-bigym-3dgs-rocm/tree/interence)
branch. The 3DGS integration remains here.

Current status, verified on 2026-08-05:

| Pull request | Contribution | Current status |
| --- | --- | --- |
| [`#56`](https://github.com/NeuracoreAI/bigym/pull/56) | atomic safetensors demonstration saves | open draft, blocked |
| [`#57`](https://github.com/NeuracoreAI/bigym/pull/57) | reset recorder state after a successful save and preserve it after failure | open draft, blocked |
| [`#58`](https://github.com/NeuracoreAI/bigym/pull/58) | cross-vendor headless EGL pixel benchmark with AMD Mesa and blank-frame validation | open draft, blocked |

These proposals do not add a model runtime, model checkpoint or the external
3DGS renderer to canonical BiGym. Their status must be rechecked before
describing them as merged or released.
