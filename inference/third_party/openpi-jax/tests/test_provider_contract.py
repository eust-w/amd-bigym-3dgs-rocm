from __future__ import annotations

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class OpenPIProviderContractTests(unittest.TestCase):
    def test_version_lock_identifies_provider_and_checkpoint(self) -> None:
        lock = json.loads((ROOT / "VERSION_LOCK.json").read_text())
        self.assertEqual(lock["provider"], "openpi-jax")
        self.assertEqual(lock["policy_contract"]["protocol_version"], 2)
        self.assertEqual(lock["policy_contract"]["action_horizon"], 10)
        self.assertEqual(lock["checkpoint"]["asset_id"], "dishwasher_unload_cutlery_long")

    def test_jax_runtime_is_isolated_from_rocm_torch(self) -> None:
        bootstrap = (ROOT / "bin" / "bootstrap.sh").read_text()
        server = (ROOT / "bin" / "serve.sh").read_text()
        self.assertIn("torch.version.hip is not None", bootstrap)
        self.assertIn('exec "$POLICY_PYTHON"', server)
        self.assertNotIn("conda run", server)

    def test_adapter_implements_provider_neutral_identity(self) -> None:
        adapter = (ROOT / "src" / "server.py").read_text()
        self.assertNotIn("import cv2", adapter)
        self.assertIn("threaded=False", adapter)
        self.assertIn("Image.open", adapter)
        self.assertIn('"provider": "openpi-jax"', adapter)
        self.assertIn('"model_id": "WuChao-Cauchy/pi05_ckpts"', adapter)
        self.assertIn('"model_revision"', adapter)
        self.assertIn('"request_id"', adapter)
        self.assertIn('"policy_infer"', adapter)
        self.assertIn('"server_total_before_final_serialize"', adapter)


if __name__ == "__main__":
    unittest.main()
