#!/usr/bin/env python3
"""Strict BiGym + AMD 3DGS closed-loop evaluator for the OpenPI HTTP adapter."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import time
from typing import Any

import cv2
import numpy as np
import requests


CAMERA_KEYS = (
    ("head", "rgb_head"),
    ("left_wrist", "rgb_left_wrist"),
    ("right_wrist", "rgb_right_wrist"),
)


def chw_rgb(observation: dict[str, Any], key: str) -> np.ndarray:
    image = np.asarray(observation[key], dtype=np.uint8)
    if image.ndim != 3 or image.shape[0] != 3:
        raise RuntimeError(f"invalid CHW RGB observation {key}: {image.shape}")
    return np.moveaxis(image, 0, -1)


def encode_png(chw: np.ndarray) -> bytes:
    rgb = np.asarray(chw, dtype=np.uint8).transpose(1, 2, 0)
    ok, buffer = cv2.imencode(".png", rgb[:, :, ::-1])
    if not ok:
        raise RuntimeError("PNG encoding failed")
    return buffer.tobytes()


def save_observation_images(
    observation: dict[str, Any], evidence_dir: Path, episode: int, label: str
) -> list[str]:
    paths: list[str] = []
    for camera_name, key in CAMERA_KEYS:
        path = evidence_dir / f"ep{episode:02d}_{label}_{camera_name}.png"
        rgb = chw_rgb(observation, key)
        if not cv2.imwrite(str(path), rgb[:, :, ::-1]):
            raise RuntimeError(f"failed to write {path}")
        paths.append(str(path))
    return paths


def success_from(env: Any, reward: Any, info: dict[str, Any]) -> bool:
    if reward is not None and float(reward) > 0.5:
        return True
    if info.get("task_success"):
        return True
    success = getattr(env, "success", None)
    if callable(success):
        try:
            return bool(success())
        except Exception:
            return False
    return bool(success)


def classify_exception(error: Exception, stage: str) -> str:
    message = f"{type(error).__name__}: {error}"
    lowered = message.lower()
    if "visual-shell" in lowered or "gaussian" in lowered or "gsplat" in lowered:
        return "visual_shell_runtime_error"
    if stage == "policy_request":
        if isinstance(error, requests.Timeout):
            return "policy_timeout"
        if isinstance(error, requests.RequestException):
            return "policy_http_error"
        return "policy_payload_error"
    if stage == "env_step":
        return "environment_step_error"
    return "environment_reset_error"


def request_chunk(
    base_url: str,
    prompt: str,
    state16: np.ndarray,
    observation: dict[str, Any],
) -> tuple[np.ndarray, float]:
    images = [encode_png(observation[key]) for _name, key in CAMERA_KEYS]
    started = time.perf_counter()
    response = requests.post(
        base_url.rstrip("/") + "/process_frame",
        data={"text": prompt, "states": json.dumps(state16.tolist())},
        files=[("image", (f"camera-{index}.png", payload, "image/png")) for index, payload in enumerate(images)],
        timeout=180,
    )
    latency_ms = (time.perf_counter() - started) * 1000.0
    response.raise_for_status()
    payload = response.json()
    if "response" not in payload:
        raise RuntimeError(f"policy response missing action chunk: {payload}")
    chunk = np.asarray(payload["response"], dtype=np.float32)
    if chunk.shape != (10, 16):
        raise RuntimeError(f"policy action chunk must be 10x16, got {chunk.shape}")
    if not np.isfinite(chunk).all():
        raise RuntimeError("policy action chunk contains non-finite values")
    return chunk, latency_ms


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bigym-root", type=Path, required=True)
    parser.add_argument("--task", default="DishwasherUnloadCutleryLong")
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--visual-shell-profile", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--n-episodes", type=int, required=True)
    parser.add_argument("--seed0", type=int, default=0)
    parser.add_argument("--max-steps", type=int)
    parser.add_argument("--tag", default="amd-jax")
    args = parser.parse_args()

    bigym_root = args.bigym_root.resolve()
    replay_dir = bigym_root / "d" / "replay_generation"
    eval_dir = bigym_root / "d" / "eval"
    sys.path.insert(0, str(replay_dir))
    sys.path.insert(0, str(eval_dir))

    from dim_utils import drop_z, pad_to_16  # type: ignore
    from env_utils import build_env, get_state  # type: ignore
    from rollout_video import RolloutRecorder, transcode_to_h264  # type: ignore
    from tasks import FREQ, TASKS, get_maxstep, resolve_task, task_to_snake  # type: ignore

    task = resolve_task(args.task)
    if task != "DishwasherUnloadCutleryLong":
        raise SystemExit("this pinned checkpoint is only accepted for DishwasherUnloadCutleryLong")
    prompt = TASKS[task]["prompt"]
    max_steps = args.max_steps if args.max_steps is not None else get_maxstep(task)
    task_dir = args.output_dir.resolve() / task_to_snake(task)
    evidence_dir = task_dir / "evidence"
    videos_dir = task_dir / "videos"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    videos_dir.mkdir(parents=True, exist_ok=True)

    env = build_env(
        task,
        render_mode="rgb_array",
        visual_shell_profile=str(args.visual_shell_profile.resolve()),
        visual_shell_strict=True,
    )
    mojo = env.action_mode._mojo
    episodes: list[dict[str, Any]] = []
    all_latencies: list[float] = []

    try:
        for episode_index in range(args.n_episodes):
            seed = args.seed0 + episode_index
            episode_started = time.perf_counter()
            recorder = RolloutRecorder(fps=float(FREQ))
            temporary_video = videos_dir / f"_tmp_ep{episode_index:02d}.mp4"
            action_queue: list[list[float]] = []
            request_latencies: list[float] = []
            request_count = 0
            clipped_values = 0
            success = False
            failure_reason: str | None = None
            failure_detail: str | None = None
            final_reward: float | None = None
            final_info: dict[str, Any] = {}
            steps_executed = 0
            initial_images: list[str] = []
            final_images: list[str] = []

            try:
                observation, _reset_info = env.reset(seed=seed)
                initial_images = save_observation_images(
                    observation, evidence_dir, episode_index, "step000"
                )
                recorder.add(chw_rgb(observation, "rgb_head"), str(temporary_video))
            except Exception as error:
                failure_reason = classify_exception(error, "env_reset")
                failure_detail = f"{type(error).__name__}: {error}"
                recorder.close()
                episodes.append(
                    {
                        "episode_index": episode_index,
                        "seed": seed,
                        "success": False,
                        "steps_executed": 0,
                        "failure_reason": failure_reason,
                        "failure_detail": failure_detail,
                        "request_count": 0,
                        "request_latency_ms": [],
                        "initial_images": [],
                        "final_images": [],
                        "video": None,
                    }
                )
                continue

            for step in range(max_steps):
                if not action_queue:
                    state = get_state(env.robot, observation, mojo)
                    state16 = pad_to_16(state, task)
                    if state16.shape != (16,) or not np.isfinite(state16).all():
                        failure_reason = "invalid_environment_state"
                        failure_detail = f"state shape={state16.shape} finite={np.isfinite(state16).all()}"
                        break
                    try:
                        chunk, latency_ms = request_chunk(
                            args.base_url, prompt, state16, observation
                        )
                    except Exception as error:
                        failure_reason = classify_exception(error, "policy_request")
                        failure_detail = f"{type(error).__name__}: {error}"
                        break
                    request_count += 1
                    request_latencies.append(latency_ms)
                    all_latencies.append(latency_ms)
                    action_queue = chunk.tolist()

                action16 = np.asarray(action_queue.pop(0), dtype=np.float32)
                action = drop_z(action16, task)
                clipped = np.clip(action, env.action_space.low, env.action_space.high)
                clipped_values += int(np.count_nonzero(clipped != action))
                try:
                    observation, reward, terminated, truncated, info = env.step(clipped)
                except Exception as error:
                    failure_reason = classify_exception(error, "env_step")
                    failure_detail = f"{type(error).__name__}: {error}"
                    break

                steps_executed = step + 1
                final_reward = None if reward is None else float(reward)
                final_info = dict(info)
                recorder.add(chw_rgb(observation, "rgb_head"), str(temporary_video))
                if success_from(env, reward, info):
                    success = True
                    break
                if terminated or truncated:
                    failure_reason = "environment_terminated_without_success"
                    break
            else:
                failure_reason = "max_steps_without_success"

            if not success and failure_reason is None:
                failure_reason = "max_steps_without_success"
            final_images = save_observation_images(
                observation, evidence_dir, episode_index, f"step{steps_executed:04d}-final"
            )
            recorder.close()
            suffix = "ok" if success else "no"
            final_video = videos_dir / (
                f"{task}_{args.tag}_cam-high_ep{episode_index:02d}_{suffix}.mp4"
            )
            if temporary_video.exists():
                os.replace(temporary_video, final_video)
                transcode_to_h264(str(final_video), fps=float(FREQ))
                video_value: str | None = str(final_video)
            else:
                video_value = None

            episodes.append(
                {
                    "episode_index": episode_index,
                    "seed": seed,
                    "success": success,
                    "steps_executed": steps_executed,
                    "max_steps": max_steps,
                    "failure_reason": None if success else failure_reason,
                    "failure_detail": None if success else failure_detail,
                    "request_count": request_count,
                    "request_latency_ms": request_latencies,
                    "action_values_clipped": clipped_values,
                    "final_reward": final_reward,
                    "final_task_success": bool(final_info.get("task_success", False)),
                    "wall_time_seconds": time.perf_counter() - episode_started,
                    "initial_images": initial_images,
                    "final_images": final_images,
                    "video": video_value,
                    "video_view": "rgb_head policy observation with strict 3DGS shell",
                }
            )
            print(
                f"episode={episode_index} seed={seed} success={success} "
                f"steps={steps_executed} requests={request_count} failure={failure_reason}"
            )
    finally:
        shell = getattr(env, "_visual_shell", None)
        shell_status = shell.status() if shell is not None else {"enabled": False}
        env.close()

    latencies = np.asarray(all_latencies, dtype=np.float64)
    successes = sum(1 for episode in episodes if episode["success"])
    strict_shell_passed = bool(
        shell_status.get("enabled")
        and shell_status.get("rendered_frames", 0) > 0
        and shell_status.get("last_error") is None
    )
    results = {
        "schema_version": 1,
        "status": "benchmark_complete" if len(episodes) == args.n_episodes else "benchmark_incomplete",
        "task": task,
        "prompt": prompt,
        "base_url": args.base_url,
        "n_episodes": args.n_episodes,
        "episodes_completed": len(episodes),
        "seed0": args.seed0,
        "max_steps": max_steps,
        "successes": successes,
        "success_rate": successes / len(episodes) if episodes else 0.0,
        "policy_requests": len(all_latencies),
        "policy_latency_ms": {
            "mean": float(latencies.mean()) if latencies.size else None,
            "p50": float(np.percentile(latencies, 50)) if latencies.size else None,
            "p95": float(np.percentile(latencies, 95)) if latencies.size else None,
            "maximum": float(latencies.max()) if latencies.size else None,
        },
        "visual_shell": {
            "profile": str(args.visual_shell_profile.resolve()),
            "strict": True,
            "runtime_passed": strict_shell_passed,
            "status": shell_status,
            "human_visual_review": "pending",
        },
        "observation_contract": {
            "state_dim": 16,
            "action_chunk_shape": [10, 16],
            "cameras": {
                "head": [3, 480, 848],
                "left_wrist": [3, 480, 640],
                "right_wrist": [3, 480, 640],
            },
        },
        "episodes": episodes,
    }
    results_path = task_dir / "results.json"
    results_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: results[key] for key in ("status", "success_rate", "policy_requests", "policy_latency_ms")}, indent=2))
    print(f"saved {results_path}")

    if results["status"] != "benchmark_complete":
        raise SystemExit(2)
    if not strict_shell_passed:
        raise SystemExit("strict visual-shell runtime gate failed")


if __name__ == "__main__":
    main()
