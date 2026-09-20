## 冒烟训练（Full-SFT）

```bash
source /opt/robotwin-env/bin/activate
cd /RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/training
mkdir -p /workspace/runtime/outputs/logs /workspace/runtime/tmp
```

### 当前推荐：6 卡（物理 2–7）+ micro=8

`micro=16` 在 8 卡 Full-SFT 上已 OOM；6 卡 FSDP 每卡分片更大，**更不建议 16**。用 8：

```bash
# 后台
nohup env GPU_COUNT=6 GPU_IDS=2,3,4,5,6,7 \
  MAX_STEPS=100 SAVE_STEPS=100 \
  MICRO_BATCH_SIZE=8 GLOBAL_BATCH_SIZE=192 \
  OUTPUT_DIR=/workspace/runtime/outputs/full_sft_6gpu_100steps_mb8 \
  LOG_FILE=/workspace/runtime/outputs/logs/full_sft_6gpu_100steps_mb8.log \
  bash train_full_sft.sh \
  > /workspace/runtime/outputs/logs/full_sft_6gpu_mb8_nohup.out 2>&1 &

echo $! > /workspace/runtime/outputs/logs/full_sft_6gpu_mb8.pid
```

`GLOBAL=192`：6×8=48，累积步=4（须整除）。

仍 OOM → `MICRO_BATCH_SIZE=4 GLOBAL_BATCH_SIZE=192`（累积=8）。

---

## 干净看日志（本机没有 `rg`，用 `grep`）

```bash
# 推荐：只看 step / 报错
tail -f /workspace/runtime/outputs/logs/full_sft_6gpu_100steps_mb8.log \
  | stdbuf -oL tr '\r' '\n' \
  | grep --line-buffered -E 'INFO - __main__ - Step|OutOfMemory|Error|Saving|checkpoint|HIP out'

# 或先看最近有没有 step（启动后前几分钟可能还是空的）
tr '\r' '\n' < /workspace/runtime/outputs/logs/full_sft_6gpu_100steps_mb8.log \
  | grep -E 'INFO - __main__ - Step|OutOfMemory|HIP out' | tail -20
```

说明：第 1 个 step 常要几分钟（编译 flex_attention 等），过滤条件在这段时间会**暂时没有输出**，属正常。可用 `amd-smi` / `ps` 确认还在跑。

---

## 说明

| 问题 | 结论 |
|------|------|
| 只用 2–7？ | 可以：`GPU_COUNT=6 GPU_IDS=2,3,4,5,6,7` |
| micro=16 够吗？ | **大概率不够**（8 卡已炸；6 卡更紧） |
| 推荐 | micro=**8**，global=**192** |
