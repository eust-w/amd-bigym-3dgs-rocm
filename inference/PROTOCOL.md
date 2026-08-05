# BiGym inference HTTP protocol v2

An inference provider must expose:

- `GET /health`: JSON with `status: "ok"`, `protocol_version: 2`, and a
  `policy_identity` object containing non-empty `provider`, `model_revision`,
  `model_id`, and `adapter_source_sha256` values. Providers that use an external
  checkpoint should additionally report `checkpoint_revision` and a stable
  checkpoint digest such as `checkpoint_metadata_sha256`.
- `POST /process_frame`: `multipart/form-data` containing `text`, `states`,
  `request_id`, and three ordered PNG files (`head`, `left_wrist`,
  `right_wrist`). `states` is a JSON array of 16 finite values.

The response must echo `request_id`, return `response` as a finite `10 x 16`
action chunk, and include these numeric `timing_ms` fields:

- `image_decode`
- `policy_infer`
- `total_before_serialize`
- `serialization_first_pass`
- `server_total_before_final_serialize`

Run `evaluation/bigym-3dgs/bin/probe_inference.sh` before evaluation. The
protocol standardizes transport and provenance; it does not require JAX,
OpenPI, PyTorch or any specific model family.
