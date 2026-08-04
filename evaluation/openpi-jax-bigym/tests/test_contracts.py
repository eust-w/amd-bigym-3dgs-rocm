from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import struct
import unittest


ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.lock = json.loads((ROOT / "VERSION_LOCK.json").read_text())
        cls.probe = load_module("probe_policy", ROOT / "src" / "probe_policy.py")
        cls.summary = load_module("summarize_results", ROOT / "src" / "summarize_results.py")

    def test_pinned_policy_contract(self) -> None:
        contract = self.lock["policy_contract"]
        self.assertEqual(contract["action_dim"], 16)
        self.assertEqual(contract["model_action_dim"], 32)
        self.assertEqual(contract["action_horizon"], 10)
        self.assertEqual(contract["camera_names"], ["high", "l_wrist", "r_wrist"])
        self.assertTrue(contract["lora"])

    def test_formal_benchmark_is_32_distinct_seeds(self) -> None:
        benchmark = self.lock["benchmark"]
        self.assertEqual(benchmark["formal_episodes"], 32)
        self.assertEqual(benchmark["seed0"], 0)
        self.assertTrue(benchmark["strict_visual_shell"])

    def test_probe_png_is_valid_rgb(self) -> None:
        payload = self.probe.png_rgb(12, 9, (1, 2, 3))
        self.assertEqual(payload[:8], b"\x89PNG\r\n\x1a\n")
        self.assertEqual(payload[12:16], b"IHDR")
        width, height = struct.unpack(">II", payload[16:24])
        self.assertEqual((width, height), (12, 9))

    def test_summary_preserves_failures(self) -> None:
        results = {
            "status": "benchmark_complete",
            "task": "DishwasherUnloadCutleryLong",
            "n_episodes": 3,
            "successes": 1,
            "success_rate": 1 / 3,
            "policy_requests": 7,
            "policy_latency_ms": {"p50": 210.0},
            "visual_shell": {"strict": True, "runtime_passed": True},
            "episodes": [
                {"success": True, "failure_reason": None},
                {"success": False, "failure_reason": "policy_timeout"},
                {"success": False, "failure_reason": "max_steps_without_success"},
            ],
        }
        summary = self.summary.summarize(results, 3)
        self.assertEqual(summary["status"], "evaluation_complete")
        self.assertEqual(summary["failure_categories"]["policy_timeout"], 1)
        self.assertFalse(summary["gates"]["human_visual_review"])

    def test_incomplete_episode_count_fails(self) -> None:
        results = {
            "status": "benchmark_complete",
            "n_episodes": 32,
            "policy_requests": 1,
            "policy_latency_ms": {"p50": 1.0},
            "visual_shell": {"strict": True, "runtime_passed": True},
            "episodes": [{}],
        }
        summary = self.summary.summarize(results, 32)
        self.assertEqual(summary["status"], "evaluation_failed")

    def test_amd_policy_runtime_isolated_from_rocm_torch(self) -> None:
        bootstrap = (ROOT / "bin" / "bootstrap_openpi_venv.sh").read_text()
        server = (ROOT / "bin" / "serve_policy.sh").read_text()
        self.assertIn("torch.version.hip is not None", bootstrap)
        self.assertIn('exec "$POLICY_PYTHON"', server)
        self.assertNotIn("conda run", server)


if __name__ == "__main__":
    unittest.main()
