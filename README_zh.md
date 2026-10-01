# ComfyUI -- 适配 GeForce RTX 50 系列 (Blackwell)

**完整文档化的 Windows 原生 ComfyUI 配置方案，支持 NVIDIA GeForce RTX 5090/5080/5070 (Blackwell 架构, sm_120) + CUDA 13.0。**

> **其他语言:** [English](README.md) | [日本語](README_ja.md) | [한국어](README_ko.md)

---

## 本仓库的特色

RTX 50 系列 GPU (Blackwell, Compute Capability sm_120) 需要包含 sm_120 内核的 PyTorch 构建。此外在 Windows 上，xformers 会替换已安装的 torch，官方 Triton 仅支持 Linux。本仓库将在 RTX 5090 上验证过的一种组合（PyTorch nightly cu130 + triton-windows，不含 xformers）整理为可复现的安装方案。

### 技术亮点

| 项目 | 详情 |
|------|------|
| **GPU 架构** | NVIDIA Blackwell (sm_120) -- RTX 5090 / 5080 / 5070 |
| **CUDA 版本** | 13.0 (cu130) |
| **PyTorch** | Nightly cu130 构建 (非稳定版, 非 cu128) |
| **Python** | 3.13 |
| **Triton** | triton-windows 分支 (官方 Triton 仅支持 Linux) |
| **xformers** | 刻意排除 (会导致 PyTorch 降级) |
| **自定义节点** | 28 个已验证节点，包含视频和音乐生成 |
| **平台** | Windows 原生 (无需 WSL2 或 Docker) |

### 要点

1. **Blackwell + Windows 原生 + CUDA 13.0** -- 无需 WSL2 或 Docker，即可在 Windows 上的 Blackwell GPU 上完整运行 ComfyUI。

2. **无 xformers 架构** -- 使用 `triton-windows` + `torch.compile` 替代与 Blackwell nightly 构建不兼容的 xformers。

3. **28 个自定义节点已验证** -- 所有节点均在 RTX 5090 (32GB VRAM) 上逐一测试通过，包括前沿视频生成 (Wan 2.1, LTX-Video, HunyuanVideo 1.5, Kandinsky 5.0, LongCat-Video) 和音乐生成 (ACE-Step, HeartMuLa)。

4. **5 种图生视频流水线已验证** -- 在 Blackwell 硬件上完成完整的 I2V 工作流验证。

5. **系统化的 Windows 特定修复方案** -- 路径分隔符问题、SageAttention 回退到 SDPA、Triton 编译回避方案等。

---

## 已验证环境

| 组件 | 版本 |
|------|------|
| 操作系统 | Windows 11 Pro (Build 26200) |
| GPU | NVIDIA GeForce RTX 5090 (32GB VRAM) |
| CPU | Intel Core Ultra 9 285K (Arrow Lake) |
| 内存 | 64GB DDR5-5600 |
| NVIDIA 驱动 | 591.55 |
| CUDA | 13.0 |
| Python | 3.13 |
| PyTorch | 2.9.1+cu130 |
| triton-windows | 3.6.0 |

---

## 快速开始

### 前置条件

- **Windows 10/11** (64位)
- **NVIDIA GeForce RTX 5090 / 5080 / 5070** (或其他 Blackwell GPU)
- **NVIDIA 驱动 580+** ([下载](https://www.nvidia.com/drivers))
- **Git** ([下载](https://git-scm.com/))
- **7-Zip** ([下载](https://7-zip.org/)) 用于解压便携版

### 一键安装 (推荐新手使用)

```
1. 下载或克隆本仓库
2. 双击 setup.bat
3. 等待安装完成 (约 20 分钟)
4. 双击 run.bat 启动 ComfyUI
5. 在浏览器中打开 http://localhost:8188
```

### 手动安装

```powershell
# 克隆本仓库
git clone https://github.com/hiroki-abe-58/ComfyUI-Win-Blackwell.git
cd ComfyUI-Win-Blackwell

# 运行安装脚本
powershell -ExecutionPolicy Bypass -File setup.ps1

# 启动 ComfyUI
.\run.bat
```

### 验证环境

```powershell
# 安装完成后，验证一切正常
python verify_env.py
```

---

## Blackwell + Windows 五大铁律

以下规则**必须**遵守。违反任何一条都会导致环境损坏。

| # | 铁律 | 原因 | 违反后的症状 |
|---|------|------|------------|
| 1 | **使用 PyTorch nightly cu130** | 这是本方案验证过的构建。不含 sm_120 内核的构建无法在 RTX 50 上运行 | `RuntimeError: sm_120 is not compatible` |
| 2 | **绝对不要安装 xformers** | 其 wheel 固定了 torch 版本，pip 会替换 cu130 构建 | 一切停止工作 |
| 3 | **从 requirements.txt 中排除 torch** | pip 会用其他 torch 覆盖 nightly cu130 构建 | 静默版本降级 |
| 4 | **添加自定义节点后务必验证** | 节点依赖可能引入其他 torch 构建 | 之前正常的环境突然损坏 |
| 5 | **清除代理环境变量** | 系统代理会阻止 pip/git 连接 | 安装失败 |

---

## 已验证的自定义节点 (28 个)

### 视频生成
- ComfyUI-WanVideoWrapper -- Wan 2.1 视频生成
- ComfyUI-LTXVideo -- LTX-Video 生成
- comfyui-videohelpersuite -- 视频合并与辅助工具
- comfyui_longcat_image -- LongCat 视频处理

### 音频/音乐生成
- ComfyUI-AceMusic -- ACE-Step 音乐生成
- ComfyUI-HeartMuLa -- HeartMuLa 音乐生成
- ComfyUI-MelBandRoFormer -- 音频源分离
- ComfyUI_FL-HeartMuLa -- HeartMuLa FL 变体

### 图像处理与编辑
- ComfyUI-Step1X-Edit -- Step1X 图像编辑
- comfyui-impact-pack -- 检测与修复
- comfyui_controlnet_aux -- ControlNet 预处理器
- comfyui_layerstyle -- 图层合成
- comfyui-depthanythingv2 -- 深度估计

### 工具与管理
- ComfyUI-Manager -- 节点管理
- 其他 14 个工具节点

---

## 已验证的图生视频工作流

| 模型 | 参数量 | FP8 大小 | 32GB VRAM 表现 |
|------|--------|---------|---------------|
| HunyuanVideo 1.5 I2V | 8.3B | ~16GB | 流畅 -- 推荐 |
| Kandinsky 5.0 Lite I2V | 2B | ~4GB | 非常流畅 |
| LTX-2 I2V | 19B | ~25GB | FP8 下可运行 |
| LongCat-Video TI2V | 13.6B | ~14.5GB | 调整后可运行 |
| Kandinsky 5.0 Pro I2V | 19B | ~40GB | 需要 CPU 卸载，速度较慢 |

---

## Windows 特定问题排查

### 模型路径错误 (`Value not in list`)

Linux 工作流使用正斜杠 (`/`)，Windows 需要反斜杠 (`\`)。

**自动修复:**
```powershell
python scripts/fix_windows_compat.py your_workflow.json
```

### SageAttention 不可用

SageAttention 在 Windows 上构建困难。请改用 SDPA (PyTorch 内置):
- 将工作流中的 `attention_mode` 从 `sageattn` 改为 `sdpa`
- 或使用 `fix_windows_compat.py` 自动修复

### PyTorch 被静默降级

安装任何包后务必验证:
```powershell
python -c "import torch; print(torch.__version__)"
```
如果不再包含 `cu130`，重新安装:
```powershell
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu130
```

---

## 更新方法

双击 `update.bat` 或运行:
```powershell
powershell -ExecutionPolicy Bypass -File update.ps1
```

---

## 常见问题

**Q: 需要 WSL2 或 Docker 吗?**
A: 不需要。本方案完全在 Windows 原生环境运行。

**Q: 可以使用 xformers 吗?**
A: 不可以。xformers 的 wheel 固定了 torch 版本，安装后会替换 cu130 构建。请改用 triton-windows + torch.compile。

**Q: 在 RTX 4090 上能用吗?**
A: 可以。cu130 向后兼容。但 RTX 4090 用户也可以使用 PyTorch 稳定版。

**Q: 模型放在哪里?**
A: 安装完成后，将模型放在 `ComfyUI_windows_portable/ComfyUI/models/` 中。共享模型存储请参考 `configs/extra_model_paths.yaml.example`。

---

## 贡献

欢迎提交 Pull Request。如果您在 Blackwell 硬件上验证了其他自定义节点或工作流，请提交 PR 更新 `custom-nodes.json`。

---

## 许可证

MIT License -- 参见 [LICENSE](LICENSE)

---

## 致谢

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) by Comfy-Org
- [triton-windows](https://github.com/woct0rdho/triton-windows) by woct0rdho
- [PyTorch](https://pytorch.org/) nightly 团队 (sm_120 支持)
- `custom-nodes.json` 中列出的所有自定义节点开发者
