#!/usr/bin/env python3
"""Verify the pinned OpenPI checkpoint and AMD visual-shell layout."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def payload_bytes(root: Path) -> int:
    return sum(
        path.stat().st_size
        for path in root.rglob("*")
        if path.is_file() and ".cache" not in path.parts
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lock", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--shell", type=Path, required=True)
    args = parser.parse_args()

    lock = json.loads(args.lock.read_text(encoding="utf-8"))
    checkpoint = args.checkpoint.resolve()
    shell = args.shell.resolve()

    required_checkpoint = [
        checkpoint / "params" / "_METADATA",
        checkpoint / "params" / "manifest.ocdbt",
        checkpoint / "assets" / lock["checkpoint"]["asset_id"] / "norm_stats.json",
    ]
    missing = [str(path) for path in required_checkpoint if not path.is_file()]
    if missing:
        raise SystemExit(f"missing checkpoint files: {missing}")

    actual_bytes = payload_bytes(checkpoint)
    expected_bytes = int(lock["checkpoint"]["bytes"])
    if actual_bytes != expected_bytes:
        raise SystemExit(
            f"checkpoint byte mismatch: expected {expected_bytes}, got {actual_bytes}"
        )

    checks = {
        "scene-shell-profile.json": lock["visual_shell"]["profile_sha256"],
        "alignment.json": lock["visual_shell"]["alignment_sha256"],
        "gaussians_shell.ply": lock["visual_shell"]["combined_ply_sha256"],
    }
    for name, expected in checks.items():
        path = shell / name
        if not path.is_file():
            raise SystemExit(f"missing shell file: {path}")
        actual = sha256(path)
        if actual != expected:
            raise SystemExit(f"sha256 mismatch for {name}: {actual}")

    profile = json.loads((shell / "scene-shell-profile.json").read_text())
    if profile.get("status") != "passed":
        raise SystemExit(f"unexpected shell status: {profile.get('status')}")
    if profile["alignment"]["path"] != "alignment.json":
        raise SystemExit("visual-shell alignment path is not pinned alignment.json")
    if profile["integration_contract"]["camera_names"] != [
        "head",
        "left_wrist",
        "right_wrist",
    ]:
        raise SystemExit("visual-shell camera contract changed")

    print(
        json.dumps(
            {
                "status": "artifacts_verified",
                "checkpoint_bytes": actual_bytes,
                "shell_profile": str(shell / "scene-shell-profile.json"),
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
