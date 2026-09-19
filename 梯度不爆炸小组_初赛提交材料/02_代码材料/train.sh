#!/usr/bin/env bash
# 一键训练入口：RoboTwin 2.0 Aloha-AgileX · 50 任务 clean 数据
# 规则：禁止使用 randomized 数据参与训练
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${ROOT_DIR}/configs/train_aloha_agilex.json"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG="$2"
      shift 2
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

export PYTHONPATH="${ROOT_DIR}/src:${PYTHONPATH:-}"

echo "[train] config=${CONFIG}"
echo "[train] data_policy=clean_only (randomized forbidden)"

python -m lingbo_vla.train \
  --config "${CONFIG}" \
  "${EXTRA_ARGS[@]}"
