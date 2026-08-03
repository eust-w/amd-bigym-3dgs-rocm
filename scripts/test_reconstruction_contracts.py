#!/usr/bin/env python3
"""Dependency-light tests for reconstruction quality selection."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SELECTOR = ROOT / "reconstruction/src/select_training_candidate.py"
ROCM_RUNNER = ROOT / "reconstruction/bin/reconstruct_rocm_gfx1100.sh"
ROCM_BUILDER = ROOT / "reconstruction/bin/build_opensplat_rocm_gfx1100.sh"
ROCM_LAUNCHER = ROOT / "reconstruction/bin/launch_rocm_gfx1100_30k.sh"
ROCM_PATCH = ROOT / "patches/opensplat-1.1.5-rocm-gfx1100.patch"
SHELL_EXPORTER = ROOT / "reconstruction/src/export_scene_shell.py"


def candidate(root: Path, name: str, metrics: dict[str, float]) -> None:
    directory = root / f"{name}-30000"
    (directory / "stats").mkdir(parents=True)
    (directory / "ckpts").mkdir()
    (directory / "stats/val_step29999.json").write_text(
        json.dumps(metrics), encoding="utf-8"
    )
    (directory / "ckpts/ckpt_29999_rank0.pt").write_bytes(b"test-only")


def run_case(
    root: Path, default_metrics: dict[str, float], mcmc_metrics: dict[str, float]
) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
    training = root / "training"
    candidate(training, "default", default_metrics)
    candidate(training, "mcmc", mcmc_metrics)
    output = root / "selection.json"
    result = subprocess.run(
        [
            sys.executable,
            str(SELECTOR),
            "--training-root",
            str(training),
            "--output",
            str(output),
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    return result, json.loads(output.read_text(encoding="utf-8"))


def main() -> None:
    with tempfile.TemporaryDirectory() as directory:
        result, payload = run_case(
            Path(directory),
            {"psnr": 31.0, "ssim": 0.94, "lpips": 0.14},
            {"psnr": 35.0, "ssim": 0.96, "lpips": 0.12},
        )
        assert result.returncode == 0, result.stderr
        assert payload["status"] == "passed"
        assert payload["formal_export_allowed"] is True
        assert payload["selected"]["name"] == "mcmc"

    with tempfile.TemporaryDirectory() as directory:
        result, payload = run_case(
            Path(directory),
            {"psnr": 28.0, "ssim": 0.90, "lpips": 0.20},
            {"psnr": 29.0, "ssim": 0.91, "lpips": 0.18},
        )
        assert result.returncode == 2
        assert payload["status"] == "quality_target_not_met"
        assert payload["formal_export_allowed"] is False

    runner = ROCM_RUNNER.read_text(encoding="utf-8")
    builder = ROCM_BUILDER.read_text(encoding="utf-8")
    launcher = ROCM_LAUNCHER.read_text(encoding="utf-8")
    patch = ROCM_PATCH.read_text(encoding="utf-8")
    shell_exporter = SHELL_EXPORTER.read_text(encoding="utf-8")
    bigym_probe = (ROOT / "scripts/probe_bigym_visual_shell.py").read_text(
        encoding="utf-8"
    )
    assert "ROCM_ARCH:-gfx1100" in runner
    assert "TRAIN_STEPS:-${STEPS:-30000}" in runner
    assert '"quality_status": "awaiting_metrics_and_visual_review"' in runner
    assert "nvidia-smi" not in runner + builder + launcher
    assert "9fb62fde8b7b8c416121d3cbdcda278ffd9682f7" in builder
    assert "CMAKE_HIP_ARCHITECTURES=\"$ROCM_ARCH\"" in builder
    assert "TRAIN_STEPS=\"${TRAIN_STEPS:-30000}\"" in launcher
    assert "ROCM_HOME" in patch and "GPU_INCLUDE_DIRS" in patch
    assert (
        "center_violation = shell & inside_center & ~floor & ~ceiling"
        in shell_exporter
    )
    assert 'camera_path.write_bytes(args.camera_path.read_bytes())' in shell_exporter
    assert '"camera_path": {' in shell_exporter
    assert 'if not args.native_only and args.profile is None:' in bigym_probe
    assert '"visual_shell": "not_run"' in bigym_probe

    print("RECONSTRUCTION_CONTRACT_TESTS_OK")


if __name__ == "__main__":
    main()
