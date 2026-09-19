#!/usr/bin/env bash
# 一键评测入口：支持 clean / randomized，每任务默认 100 次
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBMIT_ROOT="$(cd "${ROOT_DIR}/.." && pwd)"
SETTING="clean"
CHECKPOINT="${SUBMIT_ROOT}/03_模型权重/checkpoint"
CONFIG="${ROOT_DIR}/configs/eval_aloha_agilex.json"
OUTPUT_JSON="${SUBMIT_ROOT}/01_评测结果/results.json"
NUM_EPISODES=100
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --setting)
      SETTING="$2"
      shift 2
      ;;
    --checkpoint)
      CHECKPOINT="$2"
      shift 2
      ;;
    --config)
      CONFIG="$2"
      shift 2
      ;;
    --output)
      OUTPUT_JSON="$2"
      shift 2
      ;;
    --num-episodes)
      NUM_EPISODES="$2"
      shift 2
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "${SETTING}" != "clean" && "${SETTING}" != "randomized" ]]; then
  echo "[eval] invalid --setting=${SETTING} (expected clean|randomized)" >&2
  exit 1
fi

export PYTHONPATH="${ROOT_DIR}/src:${PYTHONPATH:-}"

echo "[eval] setting=${SETTING}"
echo "[eval] checkpoint=${CHECKPOINT}"
echo "[eval] output=${OUTPUT_JSON}"
echo "[eval] num_episodes=${NUM_EPISODES}"

python -m lingbo_vla.eval \
  --config "${CONFIG}" \
  --setting "${SETTING}" \
  --checkpoint "${CHECKPOINT}" \
  --output "${OUTPUT_JSON}" \
  --num-episodes "${NUM_EPISODES}" \
  "${EXTRA_ARGS[@]}"
