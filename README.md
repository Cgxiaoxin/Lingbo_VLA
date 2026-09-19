# Lingbo_VLA · 梯度不爆炸小组

灵波开发者大赛（LingBot-VLA 2.0 × RoboTwin 2.0）初赛工程仓库。

## 快速开始

1. 阅读 [`docs/resources/GETTING_STARTED.md`](docs/resources/GETTING_STARTED.md)
2. 检查提交骨架：`bash scripts/check_scaffold.sh`
3. 在 `梯度不爆炸小组_初赛提交材料/` 内完成训练、评测与材料填写
4. 截止前打包为 `梯度不爆炸小组_初赛提交材料.zip` 上传天池

## 仓库结构

```text
Lingbo_VLA/
├── 梯度不爆炸小组_初赛提交材料/   # 最终提交目录（按官方结构）
│   ├── 01_评测结果/results.json
│   ├── 02_代码材料/              # train.sh / eval.sh / configs / src
│   ├── 03_模型权重/checkpoint/
│   ├── 04_复现与调优说明/
│   ├── 05_真机创新可选任务/      # 可选
│   └── 06_小红书创作活动/
├── docs/
│   ├── official_templates/       # 主办方原始模板备份
│   └── resources/GETTING_STARTED.md
├── scripts/check_scaffold.sh
└── 灵波2026/                     # 原始模板来源（保留）
```

## 硬性规则提醒

- 训练数据：**仅 clean**（Aloha-AgileX 50 任务 × 50 条）
- **禁止** randomized 数据训练
- 评测：clean + randomized，每任务 100 次
- 初赛截止：10 月 26 日 24:00

## 核心外链

- 模型：https://github.com/Robbyant/lingbot-vla-v2
- 数据：https://huggingface.co/datasets/TianxingChen/RoboTwin2.0
- AMD 复现：https://github.com/ZiguanWang/Robotwin-radeon-cloud/blob/main/Reproduce_Guide.md
