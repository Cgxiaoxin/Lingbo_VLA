#!/usr/bin/env bash
# Local baseline smoke eval (1 GPU):
#   1) base model  -> adjust_bottle x10
#   2) robotwin ckpt -> adjust_bottle x10
# All logs/results under /workspace/runtime (persistent).
# 单任务基线冒烟评测：用 1 张 GPU，对 adjust_bottle 跑 10 episodes（脚本里写的是 10；你机器上已有结果是各 5）

set -euo pipefail

ROBOTWIN=/RoboTwin
RUNTIME=/workspace/runtime
PYTHON=/opt/robotwin-env/bin/python
PORT=13400
EVAL_EPISODES=10
TASK=adjust_bottle
TASK_CONFIG=demo_clean

BASE_MODEL="${ROBOTWIN}/experiments/lingbot_vla_v2_6b_robotwin/models/robbyant_lingbot-vla-v2-6b"
RT_ROOT=/models/robotwin-persistent/models/robbyant_lingbot-vla-v2-6b-robotwin
RT_CKPT="${RT_ROOT}"
if [[ ! -f "${RT_CKPT}/model.safetensors.index.json" ]]; then
  RT_CKPT="${RT_ROOT}/checkpoints/global_step_50000/hf_ckpt"
fi
RT_CONFIG="${RT_ROOT}/lingbotvla_cli.yaml"

LOG_DIR="${RUNTIME}/outputs/logs"
OUT_DIR="${RUNTIME}/outputs/baseline_eval"
SUMMARY="${OUT_DIR}/summary.txt"
MASTER_LOG="${LOG_DIR}/baseline_pipeline.log"

mkdir -p "${LOG_DIR}" "${OUT_DIR}/eval_result" "${RUNTIME}/tmp"
# Persist RoboTwin eval_result into workspace
if [[ -L "${ROBOTWIN}/eval_result" ]]; then
  ln -sfn "${OUT_DIR}/eval_result" "${ROBOTWIN}/eval_result"
elif [[ -d "${ROBOTWIN}/eval_result" ]]; then
  # Keep any existing content, also mirror into workspace via bind-style copy link target
  echo "[warn] ${ROBOTWIN}/eval_result exists as directory; results may stay on ephemeral root." | tee -a "${MASTER_LOG}"
else
  ln -sfn "${OUT_DIR}/eval_result" "${ROBOTWIN}/eval_result"
fi

export TMPDIR="${RUNTIME}/tmp"
export AITER_TRITON_ONLY=1
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export PYTHONPATH="/opt/aiter${PYTHONPATH:+:$PYTHONPATH}"
export ROBOTWIN_DISABLE_CUROBO=1
export ROBOTWIN_EE_PLANNER=mplib
export PYOPENGL_PLATFORM=egl
export PYTHONUNBUFFERED=1

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*" | tee -a "${MASTER_LOG}"; }

kill_port() {
  local pids
  pids=$(ss -lntp 2>/dev/null | awk -v p=":${PORT}" '$4 ~ p {print}' || true)
  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
  fi
  # Fallback: pkill policy servers
  pkill -f "deploy.lingbot_vla_v2_policy" >/dev/null 2>&1 || true
  sleep 2
}

wait_health() {
  local label=$1
  local logfile=$2
  local i
  for i in $(seq 1 600); do
    if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
      log "ERROR: ${label} server died; see ${logfile}"
      tail -n 80 "${logfile}" | tee -a "${MASTER_LOG}" || true
      return 1
    fi
    if curl -fsS --max-time 2 "http://127.0.0.1:${PORT}/healthz" >/dev/null 2>&1; then
      log "${label} server ready on :${PORT}"
      return 0
    fi
    sleep 2
  done
  log "ERROR: ${label} server health timeout; see ${logfile}"
  tail -n 80 "${logfile}" | tee -a "${MASTER_LOG}" || true
  return 1
}

start_server() {
  local label=$1
  local model=$2
  local logfile=$3
  kill_port
  : > "${logfile}"
  log "Starting ${label} server model=${model}"
  (
    cd "${ROBOTWIN}"
    bash "${ROBOTWIN}/experiments/lingbot_vla_v2_6b_robotwin/scripts/launch_official_server.sh" \
      0 "${PORT}" "${logfile}" False "${model}"
  ) &
  SERVER_PID=$!
  echo "${SERVER_PID}" > "${LOG_DIR}/${label}_server.pid"
  wait_health "${label}" "${logfile}"
}

run_eval() {
  local label=$1
  local episode_out=$2
  local started ended elapsed
  started=$(date +%s)
  log "START eval ${label}: ${TASK} x${EVAL_EPISODES} (${TASK_CONFIG})"
  cd "${ROBOTWIN}"
  "${PYTHON}" "${ROBOTWIN}/scripts/eval_policy_xpolicylab.py" \
    --task_name "${TASK}" \
    --task_config "${TASK_CONFIG}" \
    --policy_name "LingBot-VLA-v2" \
    --protocol "lingbot_vla_v2" \
    --host "127.0.0.1" \
    --port "${PORT}" \
    --device_id "0" \
    --seed "0" \
    --test_num "${EVAL_EPISODES}" \
    --expert_check "true" \
    --accept_expert_info_on_failure "true" \
    --eval_batch "false" \
    --additional_info "eval_video_log=false" \
    --episode_info_output "${episode_out}" \
    2>&1 | tee -a "${LOG_DIR}/${label}_eval.log"
  ended=$(date +%s)
  elapsed=$((ended - started))
  log "DONE eval ${label}: ${elapsed}s ($(awk -v e="${elapsed}" -v n="${EVAL_EPISODES}" 'BEGIN{printf "%.1f", e/60}') min), avg $(awk -v e="${elapsed}" -v n="${EVAL_EPISODES}" 'BEGIN{printf "%.1f", e/n}')s/ep"
  echo "${label} elapsed_sec=${elapsed}" >> "${SUMMARY}"
}

summarize_jsonl() {
  local label=$1
  local jsonl=$2
  if [[ ! -f "${jsonl}" ]]; then
    log "WARN: missing episode jsonl for ${label}: ${jsonl}"
    return 0
  fi
  "${PYTHON}" - "${jsonl}" "${label}" "${SUMMARY}" <<'PY'
import json, sys
path, label, summary = sys.argv[1:]
rows=[]
with open(path, encoding='utf-8') as f:
    for line in f:
        line=line.strip()
        if not line: continue
        try:
            rows.append(json.loads(line))
        except Exception:
            pass
n=len(rows)
succ=0
for r in rows:
    for k in ('success','Success','is_success','task_success'):
        if k in r:
            succ += 1 if bool(r[k]) else 0
            break
    else:
        # common nested
        if isinstance(r.get('info'), dict) and 'success' in r['info']:
            succ += 1 if r['info']['success'] else 0
rate = (succ/n) if n else 0.0
line=f"{label}: episodes={n} successes={succ} success_rate={rate:.3f} file={path}"
print(line)
with open(summary,'a',encoding='utf-8') as out:
    out.write(line+'\n')
PY
}

{
  echo "===== baseline pipeline $(ts) ====="
  echo "GPU count check:"
  "${PYTHON}" -c "import torch; print('torch', torch.__version__, 'hip', torch.version.hip, 'gpu', torch.cuda.is_available(), 'n', torch.cuda.device_count())"
  for p in \
    "${ROBOTWIN}/assets/objects/objaverse/list.json" \
    "${ROBOTWIN}/data/demo_clean" \
    "${BASE_MODEL}/model.safetensors.index.json" \
    "${RT_CKPT}/model.safetensors.index.json"
  do
    [[ -e "$p" ]] || { echo "MISSING $p"; exit 1; }
    echo "OK $p"
  done
} | tee -a "${MASTER_LOG}"

: > "${SUMMARY}"
echo "task=${TASK} episodes=${EVAL_EPISODES} setting=${TASK_CONFIG}" >> "${SUMMARY}"
echo "base_model=${BASE_MODEL}" >> "${SUMMARY}"
echo "robotwin_ckpt=${RT_CKPT}" >> "${SUMMARY}"
echo "note=ROCm + MPLib + expert_check=true" >> "${SUMMARY}"

# ---- Phase A: base model ----
unset LINGBOTVLA_TRAINING_CONFIG || true
start_server base "${BASE_MODEL}" "${LOG_DIR}/official_server.log"
run_eval base "${OUT_DIR}/base_adjust_bottle_episodes.jsonl"
summarize_jsonl base "${OUT_DIR}/base_adjust_bottle_episodes.jsonl"

# ---- Phase B: robotwin official ckpt ----
kill_port
export LINGBOTVLA_TRAINING_CONFIG="${RT_CONFIG}"
start_server robotwin "${RT_CKPT}" "${LOG_DIR}/robotwin_checkpoint_server.log"
run_eval robotwin "${OUT_DIR}/robotwin_adjust_bottle_episodes.jsonl"
summarize_jsonl robotwin "${OUT_DIR}/robotwin_adjust_bottle_episodes.jsonl"

kill_port
log "ALL DONE. Summary: ${SUMMARY}"
cat "${SUMMARY}" | tee -a "${MASTER_LOG}"
