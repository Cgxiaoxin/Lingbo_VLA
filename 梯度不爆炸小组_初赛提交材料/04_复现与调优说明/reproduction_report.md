# 复现与调优说明

## 1. 基础信息

- 团队名称：梯度不爆炸小组
- 使用模型版本：LingBot-VLA 2.0（lingbot-vla-v2-6b）
- 代码版本 / Commit：（提交前填写 `git rev-parse HEAD`）
- 提交 checkpoint 名称：（填写 `03_模型权重/checkpoint` 下目录名）

## 2. 训练复现

- 使用数据集：RoboTwin 2.0 · Aloha-AgileX · 50 任务 × 50 条 **clean**
- 是否使用 randomized 数据训练：否（禁止）
- 一键训练脚本：`02_代码材料/train.sh`
- 训练配置文件：`02_代码材料/configs/train_aloha_agilex.json`
- robot config：`02_代码材料/configs/robot_aloha_agilex.json`

## 3. 评测复现

- 一键评测脚本：`02_代码材料/eval.sh`
- checkpoint 加载方式：`--checkpoint 03_模型权重/checkpoint`
- clean setting 评测命令：`bash eval.sh --setting clean`
- randomized setting 评测命令：`bash eval.sh --setting randomized`
- 评测环境：AMD ROCm（待补全具体镜像 / 驱动版本）

## 4. 代码改动说明

- 是否修改 LingBot-VLA 2.0 官方代码：否（初始化阶段）
- 是否修改 RoboTwin 官方评测代码：否（初始化阶段）
- 如有修改，请说明修改内容和对应文件位置：暂无

## 5. 调优说明

- 训练参数调整：待填写
- 数据处理方式：待填写
- 模型结构改动：待填写
- 推理策略：待填写
- 主要提升点：待填写
