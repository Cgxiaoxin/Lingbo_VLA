"""评测入口脚手架。

后续对接 RoboTwin 官方评测；结果合并写入官方 results.json 模板。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lingbo VLA eval entry")
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--setting", choices=("clean", "randomized"), required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--num-episodes", type=int, default=100)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    with args.config.open("r", encoding="utf-8") as f:
        cfg = json.load(f)

    if not args.output.exists():
        raise SystemExit(f"[eval] missing results template: {args.output}")

    with args.output.open("r", encoding="utf-8") as f:
        results = json.load(f)

    setting_block = results.get("results", {}).get(args.setting)
    if not isinstance(setting_block, dict):
        raise SystemExit(f"[eval] results.json missing results.{args.setting}")

    print("[eval] config OK")
    print(f"[eval] setting={args.setting}")
    print(f"[eval] checkpoint={args.checkpoint}")
    print(f"[eval] tasks={len(setting_block)} num_episodes={args.num_episodes}")
    print(f"[eval] experiment={cfg.get('experiment_name')}")
    print(
        "[eval] TODO: run RoboTwin eval and fill attempts/successes "
        f"into {args.output}"
    )


if __name__ == "__main__":
    main()
