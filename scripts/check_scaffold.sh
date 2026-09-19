#!/usr/bin/env bash
# 初始化后快速自检：目录完整性 + 脚本可执行权限
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMIT="${ROOT}/梯度不爆炸小组_初赛提交材料"

required=(
  "${SUBMIT}/01_评测结果/results.json"
  "${SUBMIT}/02_代码材料/README.md"
  "${SUBMIT}/02_代码材料/train.sh"
  "${SUBMIT}/02_代码材料/eval.sh"
  "${SUBMIT}/02_代码材料/configs/train_aloha_agilex.json"
  "${SUBMIT}/02_代码材料/configs/eval_aloha_agilex.json"
  "${SUBMIT}/02_代码材料/configs/robot_aloha_agilex.json"
  "${SUBMIT}/03_模型权重/checkpoint/.gitkeep"
  "${SUBMIT}/04_复现与调优说明/reproduction_report.md"
  "${SUBMIT}/05_真机创新可选任务/demo_report.md"
  "${SUBMIT}/06_小红书创作活动/xiaohongshu_info.md"
)

missing=0
for f in "${required[@]}"; do
  if [[ ! -e "$f" ]]; then
    echo "[missing] $f"
    missing=1
  fi
done

chmod +x "${SUBMIT}/02_代码材料/train.sh" "${SUBMIT}/02_代码材料/eval.sh"

if [[ "${missing}" -eq 0 ]]; then
  echo "[ok] submission scaffold looks complete"
  echo "[ok] next: read docs/resources/GETTING_STARTED.md"
else
  echo "[fail] some required files are missing" >&2
  exit 1
fi
