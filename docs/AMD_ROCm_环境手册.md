# AMD Radeon Cloud · ROCm 复现环境手册

> 团队：**梯度不爆炸小组**  
> 适用平台：AMD 灵波赛事算力（Radeon Cloud Global）  
> 目的：让队员快速搞清「用哪个环境、代码在哪、权重在哪、什么该放 `/workspace`」  
> 上游官方指南：  
>
> - [Reproduce_Guide.md](https://github.com/ZiguanWang/Robotwin-radeon-cloud/blob/main/Reproduce_Guide.md)  
> - [AMD 算力领取指南](https://github.com/AMD-DEV-CONTEST/Embodied-AI-Challenge-AMD-Platform-2026-09)

---

## 1. 一句话结论

这台赛事实例 **已经是** ROCm 复现环境（external-data 镜像），**不必**再：

- 自己 `docker build` / 再套一层 Docker  
- 把 `lingbot-vla-v2` clone 进本仓库根目录  
- 把 ModelScope / Hugging Face 的 20GB+ 权重复制进 `/workspace`

官方代码、权重、clean 数据、Python 环境都已就位。本仓库 `Lingbo_VLA` 只负责 **参赛提交材料与团队工程**。

---



## 2. 你在用的是什么环境？


| 项目             | 值                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------ |
| 镜像类型           | Radeon Cloud **external-data**                                                             |
| 镜像名（参考）        | `robotwin-lingbot-vla-v2:rocm7.2.1_ubuntu24.04_py3.12_pytorch_release_2.9.1-external-data` |
| ROCm / PyTorch | ROCm **7.2.1** / PyTorch **2.9.1+rocm7.2.1**                                               |
| 规划器            | AMD 侧关闭 CuRobo，使用 **MPLib**；结果需注明 `ROCm + MPLib + expert_check=true`                       |
| 训练/评测 Python   | `/opt/robotwin-env`                                                                        |
| 数据转换 Python    | `/opt/lerobot-env`                                                                         |
| 工作目录（官方）       | `/RoboTwin`                                                                                |


创建环境：

```bash
# 启动环境
source /opt/robotwin-env/bin/activate
python -c "import torch; print(torch.__version__, torch.cuda.get_device_name(0))"
```

注意：系统自带 `/usr/bin/python3` **没有** torch，不要用它跑训练/评测。

GPU 自检：

```bash
ls -l /dev/kfd /dev/dri
rocminfo | head
```

---



## 3. 关键路径速查



### 3.1 代码（已在镜像内，无需再 clone）


| 内容                | 路径                                                                       |
| ----------------- | ------------------------------------------------------------------------ |
| RoboTwin + 实验总目录  | `/RoboTwin`                                                              |
| LingBot-VLA-v2 源码 | `/RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/source/lingbot-vla-v2` |
| 训练相关脚本            | `/RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/training`              |
| 交互式复现 Notebook    | `/RoboTwin/RoboTwin_ROCm_Reproduction.ipynb`                             |
| XPolicyLab        | `/RoboTwin/XPolicyLab`                                                   |


上游 GitHub 仅作对照版本，不必再拷到 `/workspace/Lingbo_VLA`：

- [https://github.com/Robbyant/lingbot-vla-v2](https://github.com/Robbyant/lingbot-vla-v2)  
- 复现指南固定 commit：`951475ae1b1d87553e7dc47c97b53a3d695c0d13`（以官方 Reproduce_Guide 为准）

在 Cursor / Jupyter 里方便浏览时，可做软链（**不占持久盘**）：

```bash
ln -sfn /RoboTwin /workspace/RoboTwin
```



### 3.2 权重与数据（Devzone 挂载，已就绪）

创建实例时需勾选：**Mount a model → Devzone**，否则不会出现下面的目录。

根目录：

```text
/models/robotwin-persistent/
├── assets/     # RoboTwin 仿真资产（约 16G）
├── data/       # demo_clean + lerobot 等（约 38G）
└── models/     # 预训练权重与依赖（约 51G）
```

模型权重（无需再从 ModelScope 下载到 workspace）：


| 内容                     | 路径                                                                          | 约占用   |
| ---------------------- | --------------------------------------------------------------------------- | ----- |
| 基座 LingBot-VLA-v2-6B   | `/models/robotwin-persistent/models/robbyant_lingbot-vla-v2-6b/`            | ~27G  |
| RobotWin 相关 checkpoint | `/models/robotwin-persistent/models/robbyant_lingbot-vla-v2-6b-robotwin/`   | ~24G  |
| Qwen tokenizer/config  | `/models/robotwin-persistent/models/Qwen3-VL-4B-Instruct-config-tokenizer/` | 很小    |
| MoGe-2                 | `/models/robotwin-persistent/models/moge-2-vitb-normal/`                    | ~400M |


数据：


| 内容              | 路径                                             |
| --------------- | ---------------------------------------------- |
| clean 原始演示      | `/models/robotwin-persistent/data/demo_clean/` |
| LeRobot v3 转换结果 | `/models/robotwin-persistent/data/lerobot/`    |


`/RoboTwin` 内已是软链，无需手工挂载：

```text
/RoboTwin/assets  -> /models/robotwin-persistent/assets
/RoboTwin/data    -> /models/robotwin-persistent/data
/RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/models
                  -> /models/robotwin-persistent/models
```

ModelScope / HF 链接仅作「官方来源说明」，本机优先用 `/models/...`：

- [https://modelscope.cn/models/Robbyant/lingbot-vla-v2-6b](https://modelscope.cn/models/Robbyant/lingbot-vla-v2-6b)  
- [https://huggingface.co/robbyant/lingbot-vla-v2-6b](https://huggingface.co/robbyant/lingbot-vla-v2-6b)

若确需补下缺失文件，也请下到 `/models` 侧或临时目录，**不要占满** `/workspace` **的 100G**。

---



## 4. 存储策略（最容易踩坑）

用 `df -h` 时常见布局：


| 挂载点          | 典型容量     | 是否持久             | 用途                            |
| ------------ | -------- | ---------------- | ----------------------------- |
| `/workspace` | **100G** | **是（队员自己的 PVC）** | 提交仓库、训练 checkpoint、日志、评测结果    |
| `/models`    | TB 级     | 平台 Devzone 挂载    | 官方资产 / 数据 / 预训练权重             |
| `/`（overlay） | 很大       | **实例销毁易丢失**      | 临时编译、缓存；最终产物必须拷回 `/workspace` |




### 必须放进 `/workspace` 的

- 本仓库：`/workspace/Lingbo_VLA`（提交材料）
- 训练产出：建议 `/workspace/runtime/outputs/`（或等价路径）
- 最终要打包的 checkpoint（再复制到 `梯度不爆炸小组_初赛提交材料/03_模型权重/checkpoint/`）
- 评测日志、`results.json` 定稿



### 不要塞进 `/workspace` 的

- 官方 20G+ 预训练权重（已在 `/models/...`）
- 整份 `demo_clean` / `lerobot` 数据
- `/RoboTwin` 整树拷贝（用软链即可）

创建运行时目录示例：

```bash
mkdir -p /workspace/runtime/outputs
df -h / /workspace
du -d1 -h /workspace/runtime/outputs 2>/dev/null || true
```

---



## 5. 本仓库 vs 官方运行树


|         | `/workspace/Lingbo_VLA` | `/RoboTwin`                          |
| ------- | ----------------------- | ------------------------------------ |
| 角色      | 天池提交 + 团队文档/脚手架         | 官方仿真、训练、评测运行环境                       |
| 是否改官方代码 | 提交物里放你们的封装与说明           | 在此调试；有改动需写进 `reproduction_report.md` |
| Git     | 你们自己的 GitHub 仓库         | 镜像内置，一般不当作提交仓                        |


建议工作流：

1. 在 `/RoboTwin` + `/opt/robotwin-env` 上训练 / 评测
2. 把 checkpoint、脚本改动、结果同步进 `梯度不爆炸小组_初赛提交材料/`
3. 按官方目录打 Zip 交天池

---



## 6. 网络与代理（出不了公网时）

实例默认常 **无法直连** `github.com` / 外网。本队实践：本机代理 + SSH 反向隧道。

本机（示例，端口按实际改）：

```bash
# 本机 Clash/代理监听 7890，SSH 把远端 17890 转到本机代理
ssh -R 17890:127.0.0.1:7890 -p <端口> root@<主机>
```

登录后若看到 `[proxy] tunnel 17890 active`，说明 `~/.bashrc` 已自动设置 `http_proxy`/`https_proxy`。

检查：

```bash
curl -m 8 -I https://github.com
# 或显式：
curl -m 8 -x http://127.0.0.1:17890 -I https://github.com
```

Git 可对本仓库设置：

```bash
cd /workspace/Lingbo_VLA
git config --local http.proxy http://127.0.0.1:17890
git config --local https.proxy http://127.0.0.1:17890
```

HTTPS push 还需要 GitHub Token（用户名 + PAT），与代理是两件事。

**注意：** Cursor「Ports」里把 `17890` Auto Forward 成本机端口时，不要和反向隧道搞混；隧道断了要重新带 `-R` 登录。

---



## 7. 新队员上机检查清单（5 分钟）

```bash
# 1. 持久盘与挂载
df -h /workspace /models /
ls /models/robotwin-persistent/{assets,data,models}

# 2. 权重是否在
ls /models/robotwin-persistent/models/robbyant_lingbot-vla-v2-6b/model-00001-of-00006.safetensors

# 3. ROCm 环境
source /opt/robotwin-env/bin/activate
python -c "import torch; print(torch.__version__, torch.cuda.device_count(), torch.cuda.get_device_name(0))"

# 4. 官方树
ls /RoboTwin/RoboTwin_ROCm_Reproduction.ipynb
ls /RoboTwin/experiments/lingbot_vla_v2_6b_robotwin/source/lingbot-vla-v2

# 5. 团队仓库
ls /workspace/Lingbo_VLA/梯度不爆炸小组_初赛提交材料
bash /workspace/Lingbo_VLA/scripts/check_scaffold.sh

# 6.（可选）软链方便浏览
ln -sfn /RoboTwin /workspace/RoboTwin
```

全部 OK 后，打开 Notebook 按官方步骤跑一小段评测（如单任务少量 episode），再进入正式训练。

---



## 8. 常见误区


| 误区                              | 正确做法                                       |
| ------------------------------- | ------------------------------------------ |
| 「要先 clone lingbot 到 Lingbo_VLA」 | 用 `/RoboTwin/.../lingbot-vla-v2`           |
| 「要从 ModelScope 下权重到 workspace」  | 用 `/models/robotwin-persistent/models/...` |
| 「系统 python 就能训」                 | `source /opt/robotwin-env/bin/activate`    |
| 「根盘很大可以随便存 checkpoint」          | 最终结果必须进 `/workspace`                       |
| 「randomized 数据也可以拿来训」           | **禁止**；仅 clean 训练                          |
| 「再起一个 Docker 套官方镜像」             | 云实例里不要再套第二层 Docker                         |


---



## 9. 相关文档

- 参赛流程与提交节奏：`[resources/GETTING_STARTED.md](resources/GETTING_STARTED.md)`  
- 官方模板备份：`[official_templates/](official_templates/)`  
- 上游复现指南：[https://github.com/ZiguanWang/Robotwin-radeon-cloud/blob/main/Reproduce_Guide.md](https://github.com/ZiguanWang/Robotwin-radeon-cloud/blob/main/Reproduce_Guide.md)

文档随实例实测更新；若平台改了挂载路径或镜像版本，请直接改本文并在 Git 里说明。