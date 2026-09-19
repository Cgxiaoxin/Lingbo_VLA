# 02_代码材料

团队：**梯度不爆炸小组**  
基座模型：[LingBot-VLA 2.0](https://github.com/Robbyant/lingbot-vla-v2)  
仿真平台：[RoboTwin 2.0](https://robotwin-platform.github.io)（Aloha-AgileX，50 任务 × 50 条 **clean** 数据）

## 目录结构

```text
02_代码材料/
├── README.md          # 本文件
├── train.sh           # 一键训练入口
├── eval.sh            # 一键评测入口（clean / randomized）
├── configs/           # 训练 / 评测 / robot 配置
└── src/               # 自定义训练与评测封装代码
```

## 依赖与环境

本队在 AMD 赛事算力上开发，推荐对齐官方 ROCm 复现指南：

- 参考样例：https://github.com/ZiguanWang/Robotwin-radeon-cloud/blob/main/Reproduce_Guide.md
- AMD 算力领取：https://github.com/AMD-DEV-CONTEST/Embodied-AI-Challenge-AMD-Platform-2026-09

环境就绪后，确认代理隧道可用（本机 Clash `7890` → 服务器 `17890`），再安装依赖 / 拉取权重。

## 数据规则（必读）

- **仅允许** RoboTwin 2.0 Aloha-AgileX 的 **clean** 数据参与训练（每任务 50 条）。
- **禁止** 使用 randomized 数据训练。
- 评测需同时提交 **clean** 与 **randomized** 两个 setting，每任务测试 **100** 次。

## 训练

```bash
bash train.sh
# 或覆盖配置：
bash train.sh --config configs/train_aloha_agilex.json
```

## 评测

```bash
# clean setting
bash eval.sh --setting clean --checkpoint ../03_模型权重/checkpoint

# randomized setting
bash eval.sh --setting randomized --checkpoint ../03_模型权重/checkpoint
```

评测结果写入 `../01_评测结果/results.json`（字段需与官方模板一致）。

## 与官方代码的关系

当前 `src/` 为可复现的封装脚手架。正式训练/评测将对接：

1. `lingbot-vla-v2` 官方训练入口  
2. RoboTwin 官方评测流程  

若修改官方代码，请在本 README 与 `04_复现与调优说明/reproduction_report.md` 中写明改动文件与原因。
