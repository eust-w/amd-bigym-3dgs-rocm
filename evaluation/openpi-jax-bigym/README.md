# Compatibility entrypoint

The former combined OpenPI + BiGym directory has been split into:

- [`../bigym-3dgs/`](../bigym-3dgs/README.md): provider-neutral BiGym, 3DGS,
  three-camera recording, trajectory and validation pipeline;
- [`../../inference/third_party/openpi-jax/`](../../inference/third_party/openpi-jax/README.md):
  optional third-party OpenPI JAX inference provider.

The scripts below are thin compatibility wrappers for one migration cycle. New
automation should use the new paths and set `INFERENCE_PROVIDER` and
`INFERENCE_BASE_URL` explicitly.
