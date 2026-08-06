"""Strict, dependency-free validation for inference protocol v2 evidence."""

from __future__ import annotations

import math
import re
from typing import Any


POLICY_IDENTITY_KEYS = (
    "provider",
    "model_id",
    "model_revision",
    "adapter_source_sha256",
)
SERVER_TIMING_KEYS = (
    "image_decode",
    "policy_infer",
    "total_before_serialize",
    "serialization_first_pass",
    "server_total_before_final_serialize",
)
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")


def is_nonnegative_finite_number(value: Any) -> bool:
    return (
        type(value) in (int, float)
        and math.isfinite(float(value))
        and float(value) >= 0.0
    )


def validate_policy_health(payload: Any) -> dict[str, Any]:
    identity = payload.get("policy_identity") if isinstance(payload, dict) else None
    if (
        not isinstance(payload, dict)
        or payload.get("status") != "ok"
        or payload.get("protocol_version") != 2
        or not isinstance(identity, dict)
    ):
        raise ValueError("health response is not inference protocol v2")
    for key in POLICY_IDENTITY_KEYS:
        value = identity.get(key)
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"policy_identity.{key} must be a non-empty string")
    source_sha256 = identity["adapter_source_sha256"]
    if not SHA256_PATTERN.fullmatch(source_sha256):
        raise ValueError(
            "policy_identity.adapter_source_sha256 must be 64 lowercase hex characters"
        )
    return payload


def validate_server_timing(payload: Any) -> dict[str, int | float]:
    if not isinstance(payload, dict):
        raise ValueError("timing_ms must be an object")
    invalid = [
        key
        for key in SERVER_TIMING_KEYS
        if not is_nonnegative_finite_number(payload.get(key))
    ]
    if invalid:
        raise ValueError(
            "timing_ms fields must be finite and non-negative: " + ", ".join(invalid)
        )
    return payload
