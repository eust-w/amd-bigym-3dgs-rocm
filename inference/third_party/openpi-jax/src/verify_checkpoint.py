#!/usr/bin/env python3
"""Verify the pinned OpenPI Orbax checkpoint layout and payload size."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def payload_bytes(root: Path) -> int:
    return sum(
        path.stat().st_size
        for path in root.rglob("*")
        if path.is_file() and ".cache" not in path.parts
    )


def payload_files(root: Path) -> int:
    return sum(
        1
        for path in root.rglob("*")
        if path.is_file() and ".cache" not in path.parts
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lock", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    args = parser.parse_args()

    lock = json.loads(args.lock.read_text(encoding="utf-8"))["checkpoint"]
    checkpoint = args.checkpoint.resolve()
    required = [
        checkpoint / "params" / "_METADATA",
        checkpoint / "params" / "manifest.ocdbt",
        checkpoint / "assets" / lock["asset_id"] / "norm_stats.json",
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise SystemExit(f"missing checkpoint files: {missing}")

    actual_bytes = payload_bytes(checkpoint)
    actual_files = payload_files(checkpoint)
    if actual_bytes != int(lock["bytes"]):
        raise SystemExit(
            f"checkpoint byte mismatch: expected {lock['bytes']}, got {actual_bytes}"
        )
    if actual_files != int(lock["files"]):
        raise SystemExit(
            f"checkpoint file-count mismatch: expected {lock['files']}, got {actual_files}"
        )
    print(json.dumps({"status": "checkpoint_verified", "bytes": actual_bytes, "files": actual_files}, indent=2))


if __name__ == "__main__":
    main()
