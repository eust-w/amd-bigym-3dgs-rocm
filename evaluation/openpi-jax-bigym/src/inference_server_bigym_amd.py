#!/usr/bin/env python3
"""ROCm-safe BiGym HTTP adapter for the pinned OpenPI policy.

The upstream adapter imports OpenCV and runs Flask in threaded mode. On the
gfx1100 validation host that combination corrupted the native heap on the first
JAX request. This adapter keeps the wire contract unchanged while using Pillow
for PNG decoding and a single request thread.
"""

from __future__ import annotations

import argparse
import hashlib
from io import BytesIO
import json
import logging
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid

import numpy as np
from flask import Flask, request
from PIL import Image


OPENPI_DIR = Path(os.environ["OPENPI_DIR"]).resolve()
sys.path.insert(0, str(OPENPI_DIR))
import inference_server  # noqa: E402


log = logging.getLogger("bigym_infer_amd")
app = Flask(__name__)
policy = None
service_identity = None
CAM_ORDER = ("high", "l_wrist", "r_wrist")


@app.post("/process_frame")
def process_frame():
    request_started = time.perf_counter()
    request_id = request.form.get("request_id") or uuid.uuid4().hex
    try:
        prompt = request.form.get("text", "")
        state16 = np.asarray(
            json.loads(request.form.get("states", "[]")), dtype=np.float32
        )
        if state16.shape != (16,):
            return json.dumps(
                {
                    "error": f"expected state shape (16,), got {state16.shape}",
                    "request_id": request_id,
                }
            ), 400

        files = request.files.getlist("image")
        if len(files) != 3:
            return json.dumps(
                {"error": f"expected 3 images, got {len(files)}", "request_id": request_id}
            ), 400

        decode_started = time.perf_counter()
        images = {}
        for name, uploaded in zip(CAM_ORDER, files, strict=True):
            with Image.open(BytesIO(uploaded.read())) as decoded:
                images[name] = np.asarray(decoded.convert("RGB"), dtype=np.uint8).copy()
        decode_ms = (time.perf_counter() - decode_started) * 1000.0

        assert policy is not None
        infer_started = time.perf_counter()
        output = policy.infer({"state": state16, "images": images, "prompt": prompt})
        infer_ms = (time.perf_counter() - infer_started) * 1000.0
        actions = np.asarray(output["actions"], dtype=np.float32)
        if actions.shape != (10, 16):
            raise ValueError(f"expected actions (10, 16), got {actions.shape}")
        serialize_started = time.perf_counter()
        response_payload = {
            "response": actions.tolist(),
            "request_id": request_id,
            "timing_ms": {
                "image_decode": decode_ms,
                "policy_infer": infer_ms,
                "total_before_serialize": (time.perf_counter() - request_started) * 1000.0,
            },
        }
        json.dumps(response_payload)
        response_payload["timing_ms"]["serialization_first_pass"] = (
            time.perf_counter() - serialize_started
        ) * 1000.0
        response_payload["timing_ms"]["server_total_before_final_serialize"] = (
            time.perf_counter() - request_started
        ) * 1000.0
        response_json = json.dumps(response_payload)
        log.info(
            "request_id=%s prompt=%r state=%s images=%s actions=%s timing_ms=%s",
            request_id,
            prompt,
            state16.shape,
            [images[name].shape for name in CAM_ORDER],
            actions.shape,
            response_payload["timing_ms"],
        )
        return response_json
    except Exception as exc:  # noqa: BLE001
        log.exception("request_id=%s process_frame failed", request_id)
        return json.dumps({"error": str(exc), "request_id": request_id}), 500


@app.get("/health")
def health():
    return json.dumps(
        {
            "status": "ok",
            "backend": "jax-rocm",
            "adapter": "pillow-single-thread-timing-v2",
            "protocol_version": 2,
            "policy_identity": service_identity,
        }
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="ROCm-safe BiGym OpenPI adapter")
    inference_server.add_args(parser)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    global policy, service_identity
    checkpoint_dir = Path(args.checkpoint_dir).resolve()
    metadata_path = checkpoint_dir / "params" / "_METADATA"
    try:
        openpi_revision = subprocess.run(
            ["git", "-C", str(OPENPI_DIR), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        openpi_revision = None
    service_identity = {
        "checkpoint_dir": str(checkpoint_dir),
        "checkpoint_revision": os.environ.get("POLICY_CHECKPOINT_REVISION"),
        "checkpoint_metadata_sha256": (
            hashlib.sha256(metadata_path.read_bytes()).hexdigest()
            if metadata_path.is_file()
            else None
        ),
        "openpi_revision": openpi_revision,
        "adapter_source_sha256": hashlib.sha256(
            Path(__file__).resolve().read_bytes()
        ).hexdigest(),
    }
    log.info("Building policy from checkpoint %s", args.checkpoint_dir)
    policy = inference_server.build_policy(args)
    log.info("Policy ready on %s:%d", args.host, args.port)
    app.run(host=args.host, port=args.port, threaded=False, use_reloader=False)


if __name__ == "__main__":
    main()
