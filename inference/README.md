# Inference providers

The BiGym evaluator is model-agnostic. It talks to an inference service through
the versioned HTTP v2 contract in [`PROTOCOL.md`](PROTOCOL.md); model runtimes
and checkpoints stay outside the simulator process.

Third-party adapters live under `inference/third_party/<provider>/`. The first
reference adapter is [`openpi-jax/`](third_party/openpi-jax/README.md), but it is
not required by the evaluator. A new provider only needs to implement the two
HTTP endpoints, return a frozen service identity and pass the generic probe.

Keep provider-specific source pins, checkpoint validation, GPU setup and
licenses inside that provider directory. Do not import a provider's framework
from the PyTorch/gsplat BiGym process.
