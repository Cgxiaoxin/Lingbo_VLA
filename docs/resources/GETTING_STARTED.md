# 梯度不爆炸小组 · 开始指南

截止：**初赛提交 10 月 26 日 24:00**（天池平台 Zip 提交）

## 0. 本仓库已经帮你做好的事

- 按官方模板建好提交目录：`梯度不爆炸小组_初赛提交材料/`
- `results.json` / 复现说明 / 真机 Demo 说明 / 小红书信息占位
- `02_代码材料` 下的 `train.sh` / `eval.sh` / configs / src 脚手架

## 1. 建议推进顺序（仿真必做）

| 阶段 | 做什么 | 产出 |
|------|--------|------|
| A. 环境 | 领取 AMD 算力，对齐 ROCm 复现镜像 | 可跑通官方 hello-world |
| B. 资源 | 拉 LingBot-VLA 2.0 代码与权重；准备 RoboTwin **clean** 数据 | 本地/挂载路径可用 |
| C. 基线 | 不改结构，先跑通 train → eval(clean) | 第一个 checkpoint + 部分任务分 |
| D. 调优 | 改超参 / 数据增强（仍限 clean）/ 推理策略 | 更好的 success rate |
| E. 全量评测 | 50 任务 × clean/randomized × 100 episodes | 填满 `results.json` |
| F. 打包 | 按目录打 Zip，天池提交 | `梯度不爆炸小组_初赛提交材料.zip` |

## 2. 官方资源速查

| 资源 | 链接 |
|------|------|
| LingBot-VLA 2.0 介绍 | https://technology.robbyant.com/lingbot-vla-v2 |
| 代码仓库 | https://github.com/Robbyant/lingbot-vla-v2 |
| 权重 Hugging Face | https://huggingface.co/robbyant/lingbot-vla-v2-6b |
| 权重 ModelScope | https://modelscope.cn/collections/Robbyant/LingBot-VLA-V2 |
| RoboTwin 主页 | https://robotwin-platform.github.io |
| 数据集（仅用 clean） | https://huggingface.co/datasets/TianxingChen/RoboTwin2.0 |
| AMD 算力指南 | https://github.com/AMD-DEV-CONTEST/Embodied-AI-Challenge-AMD-Platform-2026-09 |
| AMD ROCm 复现样例 | https://github.com/ZiguanWang/Robotwin-radeon-cloud/blob/main/Reproduce_Guide.md |

## 3. 本机网络（AMD 云）

服务器默认无公网，需本机开代理后 SSH 反向隧道：

```bash
ssh -R 17890:127.0.0.1:7890 -p 31169 root@36.150.116.206
```

登录后应看到 `[proxy] tunnel 17890 active`。本仓库 Git 已配置走 `127.0.0.1:17890`。

## 4. 下一步可执行命令（脚手架自检）

```bash
cd "梯度不爆炸小组_初赛提交材料/02_代码材料"
chmod +x train.sh eval.sh
bash train.sh
bash eval.sh --setting clean
```

当前 train/eval 仅做配置与规则校验（纯标准库，无需额外 pip）；接上官方训练/评测代码后替换 `src/lingbo_vla/*.py` 内 TODO 即可。

## 5. 提交前检查清单

- [ ] `team_id` 已写入 `01_评测结果/results.json`
- [ ] clean / randomized 各 50 任务 attempts=100（或官方要求值）
- [ ] checkpoint 与评测结果对应
- [ ] `reproduction_report.md` 写清复现步骤
- [ ] Zip 命名：`梯度不爆炸小组_初赛提交材料.zip`
- [ ] （可选）真机 Demo 视频 + 说明；（可选）小红书链接
