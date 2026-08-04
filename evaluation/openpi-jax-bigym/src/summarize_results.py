#!/usr/bin/env python3
"""Create a compact, machine-readable acceptance summary from evaluator output."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
from typing import Any


def summarize(results: dict[str, Any], expected_episodes: int) -> dict[str, Any]:
    episodes = results.get("episodes", [])
    failures = Counter(
        episode.get("failure_reason") or "unclassified"
        for episode in episodes
        if not episode.get("success")
    )
    structural_pass = (
        results.get("status") == "benchmark_complete"
        and results.get("n_episodes") == expected_episodes
        and len(episodes) == expected_episodes
    )
    visual_shell_pass = bool(
        results.get("visual_shell", {}).get("strict")
        and results.get("visual_shell", {}).get("runtime_passed")
    )
    policy_pass = (
        int(results.get("policy_requests", 0)) > 0
        and results.get("policy_latency_ms", {}).get("p50") is not None
    )
    return {
        "schema_version": 1,
        "status": "evaluation_complete" if structural_pass and visual_shell_pass and policy_pass else "evaluation_failed",
        "task": results.get("task"),
        "episodes": expected_episodes,
        "successes": int(results.get("successes", 0)),
        "success_rate": float(results.get("success_rate", 0.0)),
        "policy_requests": int(results.get("policy_requests", 0)),
        "policy_latency_ms": results.get("policy_latency_ms"),
        "failure_categories": dict(sorted(failures.items())),
        "gates": {
            "episode_structure": structural_pass,
            "policy_requests": policy_pass,
            "strict_visual_shell_runtime": visual_shell_pass,
            "human_visual_review": False,
        },
        "claim_boundary": (
            "evaluation execution is complete; visual publication remains pending until "
            "the recorded three-camera frames are manually reviewed"
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--expected-episodes", type=int, required=True)
    args = parser.parse_args()
    results = json.loads(args.results.read_text(encoding="utf-8"))
    summary = summarize(results, args.expected_episodes)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    if summary["status"] != "evaluation_complete":
        raise SystemExit(2)


if __name__ == "__main__":
    main()
