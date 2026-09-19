"""训练入口脚手架。

后续将在此对接官方 lingbot-vla-v2 训练脚本与 RoboTwin clean 数据集。
当前仅校验配置与数据策略，避免误用 randomized 数据。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lingbo VLA train entry")
    parser.add_argument("--config", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    with args.config.open("r", encoding="utf-8") as f:
        cfg = json.load(f)

    split = str(cfg.get("data", {}).get("split", "")).lower()
    if split != "clean":
        raise SystemExit(
            f"[train] refused: data.split={split!r}. "
            "Contest rules require clean-only training."
        )

    print("[train] config OK")
    print(f"[train] experiment={cfg.get('experiment_name')}")
    print(f"[train] model={cfg.get('model', {}).get('pretrained')}")
    print(f"[train] data.split={split}, tasks={cfg.get('data', {}).get('tasks')}")
    print(
        "[train] TODO: wire to official LingBot-VLA 2.0 trainer "
        "(see docs/resources/GETTING_STARTED.md)"
    )


if __name__ == "__main__":
    main()
