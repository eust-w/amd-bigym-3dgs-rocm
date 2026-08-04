#!/usr/bin/env python3
"""ROCm-safe BiGym HTTP adapter for the pinned OpenPI policy.

The upstream adapter imports OpenCV and runs Flask in threaded mode. On the
gfx1100 validation host that combination corrupted the native heap on the first
JAX request. This adapter keeps the wire contract unchanged while using Pillow
for PNG decoding and a single request thread.
"""

from __future__ import annotations

import argparse
from io import BytesIO
import json
import logging
import os
from pathlib import Path
import sys

import numpy as np
from flask import Flask, request
from PIL import Image


OPENPI_DIR = Path(os.environ["OPENPI_DIR"]).resolve()
sys.path.insert(0, str(OPENPI_DIR))
import inference_server  # noqa: E402


log = logging.getLogger("bigym_infer_amd")
app = Flask(__name__)
policy = None
CAM_ORDER = ("high", "l_wrist", "r_wrist")


@app.post("/process_frame")
def process_frame():
    try:
        prompt = request.form.get("text", "")
        state16 = np.asarray(
            json.loads(request.form.get("states", "[]")), dtype=np.float32
        )
        if state16.shape != (16,):
            return json.dumps({"error": f"expected state shape (16,), got {state16.shape}"}), 400

        files = request.files.getlist("image")
        if len(files) != 3:
            return json.dumps({"error": f"expected 3 images, got {len(files)}"}), 400

        images = {}
        for name, uploaded in zip(CAM_ORDER, files, strict=True):
            with Image.open(BytesIO(uploaded.read())) as decoded:
                images[name] = np.asarray(decoded.convert("RGB"), dtype=np.uint8).copy()

        assert policy is not None
        output = policy.infer({"state": state16, "images": images, "prompt": prompt})
        actions = np.asarray(output["actions"], dtype=np.float32)
        if actions.shape != (10, 16):
            raise ValueError(f"expected actions (10, 16), got {actions.shape}")
        log.info(
            "request prompt=%r state=%s images=%s actions=%s",
            prompt,
            state16.shape,
            [images[name].shape for name in CAM_ORDER],
            actions.shape,
        )
        return json.dumps({"response": actions.tolist()})
    except Exception as exc:  # noqa: BLE001
        log.exception("process_frame failed")
        return json.dumps({"error": str(exc)}), 500


@app.get("/health")
def health():
    return json.dumps({"status": "ok", "backend": "jax-rocm", "adapter": "pillow-single-thread"})


def main() -> None:
    parser = argparse.ArgumentParser(description="ROCm-safe BiGym OpenPI adapter")
    inference_server.add_args(parser)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    global policy
    log.info("Building policy from checkpoint %s", args.checkpoint_dir)
    policy = inference_server.build_policy(args)
    log.info("Policy ready on %s:%d", args.host, args.port)
    app.run(host=args.host, port=args.port, threaded=False, use_reloader=False)


if __name__ == "__main__":
    main()
