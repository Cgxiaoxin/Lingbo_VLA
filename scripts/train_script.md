## 简单测试（smoke test）

```bash
# 激活环境
source /opt/robotwin-env/bin/activate

# 进入训练目录
cd /RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/training

# 启动 8 卡，微型训练（脚本内已带 AITER_TRITON_ONLY 等 ROCm 变量）
GPU_COUNT=8 MAX_STEPS=100 SAVE_STEPS=100 \
  OUTPUT_DIR=/workspace/runtime/outputs/full_sft_8gpu_100steps \
  bash train_full_sft.sh
```

若仍报 `Unrecognized ... LingbotVLAV2Config`，先手动导出再跑：

```bash
export AITER_TRITON_ONLY=1
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export PYTHONPATH=/opt/aiter${PYTHONPATH:+:$PYTHONPATH}
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export TMPDIR=/workspace/runtime/tmp
mkdir -p "$TMPDIR"
```

---



## 后台训练方法

### 方法 1：使用 nohup（无 tmux/screen 时推荐）

```bash
# 激活环境
source /opt/robotwin-env/bin/activate

# 日志目录
mkdir -p /workspace/runtime/outputs/logs

# 进入训练目录
cd /RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/training

# 启动训练并挂后台，日志输出到指定文件
nohup env GPU_COUNT=8 MAX_STEPS=100 SAVE_STEPS=100 \
  OUTPUT_DIR=/workspace/runtime/outputs/full_sft_8gpu_100steps \
  bash train_full_sft.sh \
  > /workspace/runtime/outputs/logs/full_sft_smoke_nohup.out 2>&1 &

# 保存后台进程号
echo $! > /workspace/runtime/outputs/logs/full_sft_smoke.pid

# 查看/实时追踪日志
tail -f /workspace/runtime/outputs/logs/full_sft_smoke_nohup.out
```



#### 断线重连后继续查看日志：

```bash
tail -f /workspace/runtime/outputs/logs/full_sft_smoke_nohup.out
```



#### 或查看训练脚本自带日志：

```bash
tail -f /workspace/runtime/outputs/logs/full_sft_8gpu_100steps.log
```

---

### 方法 2：用 tmux 或 screen（如有权限/习惯）

```bash
# 装 tmux 或 screen（如无权限可跳过）
apt-get update && apt-get install -y tmux   # 或 screen

# 新建 tmux 会话
tmux new -s train
# （进入会话后按上述方式启动训练即可）
# 断线/重连后恢复会话
tmux attach -t train
```

> 注：tmux 一般比 screen 更好用。如无权限安装，直接用 nohup 足够。

