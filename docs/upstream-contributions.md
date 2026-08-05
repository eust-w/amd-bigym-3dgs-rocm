# Contributions proposed to canonical BiGym

Reusable simulator improvements are proposed directly to
[`NeuracoreAI/bigym`](https://github.com/NeuracoreAI/bigym). Provider-specific
OpenPI, checkpoint and 3DGS dependencies remain in this integration repository.

Current status, verified on 2026-08-05:

| Pull request | Contribution | Current status |
| --- | --- | --- |
| [`#56`](https://github.com/NeuracoreAI/bigym/pull/56) | atomic safetensors demonstration saves | open draft, blocked |
| [`#57`](https://github.com/NeuracoreAI/bigym/pull/57) | reset recorder state after a successful save and preserve it after failure | open draft, blocked |
| [`#58`](https://github.com/NeuracoreAI/bigym/pull/58) | cross-vendor headless EGL pixel benchmark with AMD Mesa and blank-frame validation | open draft, blocked |

These proposals do not add JAX, a model checkpoint or the external 3DGS
renderer to canonical BiGym. Their status must be rechecked before describing
them as merged or released.
