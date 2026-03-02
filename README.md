# ComfyUI for GeForce RTX 50-Series (Blackwell)

**The first fully documented, Windows-native ComfyUI setup for NVIDIA GeForce RTX 5090/5080/5070 (Blackwell architecture, sm_120) with CUDA 13.0.**

> **Other languages:** [日本語](README_ja.md) | [中文](README_zh.md) | [한국어](README_ko.md)

---

## What Makes This Special

RTX 50-series GPUs (Blackwell, Compute Capability sm_120) are **not supported by PyTorch stable releases** as of early 2026. Running ComfyUI on these GPUs requires specific versions and workarounds that are not documented anywhere else in a single, reproducible package.

### Technical Highlights

| Feature | Details |
|---------|---------|
| **GPU Architecture** | NVIDIA Blackwell (sm_120) -- RTX 5090 / 5080 / 5070 |
| **CUDA Version** | 13.0 (cu130) -- the latest CUDA runtime |
| **PyTorch** | Nightly cu130 build (not stable, not cu128) |
| **Python** | 3.13 (latest) |
| **Triton** | triton-windows fork (official Triton is Linux-only) |
| **xformers** | Deliberately excluded (causes PyTorch downgrade) |
| **Custom Nodes** | 28 verified nodes including video & music generation |
| **Platform** | Windows Native (no WSL2, no Docker required) |

### Why This Is Unique

1. **Blackwell + Windows Native + CUDA 13.0** -- One of the world's first documented setups that runs ComfyUI on Blackwell GPUs entirely on Windows without WSL2 or Docker.

2. **No xformers Architecture** -- Pioneers the use of `triton-windows` + `torch.compile` as a replacement for xformers, which is incompatible with Blackwell nightly builds.

3. **28 Custom Nodes Verified** -- All nodes have been individually tested on RTX 5090 (32GB VRAM), including cutting-edge video generation (Wan 2.1, LTX-Video, HunyuanVideo 1.5, Kandinsky 5.0, LongCat-Video) and music generation (ACE-Step, HeartMuLa).

4. **5 Image-to-Video Pipelines Verified** -- Complete I2V workflow validation on Blackwell hardware.

5. **Windows-specific Fixes Documented** -- Path separator issues, SageAttention fallback to SDPA, Triton compilation workarounds, and more.

---

## Verified Environment

| Component | Version |
|-----------|---------|
| OS | Windows 11 Pro (Build 26200) |
| GPU | NVIDIA GeForce RTX 5090 (32GB VRAM) |
| CPU | Intel Core Ultra 9 285K (Arrow Lake) |
| RAM | 64GB DDR5-5600 |
| NVIDIA Driver | 591.55 |
| CUDA | 13.0 |
| Python | 3.13 |
| PyTorch | 2.9.1+cu130 |
| triton-windows | 3.6.0 |

---

## Quick Start

### Prerequisites

- **Windows 10/11** (64-bit)
- **NVIDIA GeForce RTX 5090 / 5080 / 5070** (or any Blackwell GPU)
- **NVIDIA Driver 580+** ([Download](https://www.nvidia.com/drivers))
- **Git** ([Download](https://git-scm.com/))
- **7-Zip** ([Download](https://7-zip.org/)) for extracting the portable build

### One-Click Setup (Recommended for Beginners)

```
1. Download or clone this repository
2. Double-click setup.bat
3. Wait for the installation to complete (~20 minutes)
4. Double-click run.bat to start ComfyUI
5. Open http://localhost:8188 in your browser
```

### Manual Setup

```powershell
# Clone this repository
git clone https://github.com/hiroki-abe-58/ComfyUI-GeForce-Blackwell.git
cd ComfyUI-GeForce-Blackwell

# Run the setup script
powershell -ExecutionPolicy Bypass -File setup.ps1

# Start ComfyUI
.\run.bat
```

### Verify Your Environment

```powershell
# After setup, verify everything is working
python verify_env.py
```

Expected output:
```
============================================================
  Blackwell (sm_120) Environment Verification
============================================================

  [OK]   Python
  [OK]   NVIDIA Driver
  [OK]   PyTorch
  [OK]   Triton
  [OK]   Core Packages
  [OK]   torch.compile

  Environment is ready for Blackwell GPU!
```

---

## Repository Structure

```
ComfyUI-GeForce-Blackwell/
├── setup.bat                 # One-click setup (double-click)
├── setup.ps1                 # Full setup script (PowerShell)
├── run.bat                   # Start ComfyUI
├── update.bat                # Update everything
├── update.ps1                # Update script (PowerShell)
├── verify_env.py             # Environment verification
├── requirements-core.txt     # Core dependencies (torch excluded)
├── custom-nodes.json         # 28 verified custom nodes
├── configs/
│   └── extra_model_paths.yaml.example
└── scripts/
    ├── install_custom_nodes.ps1   # Batch node installer
    └── fix_windows_compat.py      # Workflow compatibility fixer
```

---

## The 5 Rules of Blackwell on Windows

These rules **must** be followed. Violating any of them will break your environment.

| # | Rule | Why | What Happens If Violated |
|---|------|-----|--------------------------|
| 1 | **Use PyTorch nightly cu130** | Stable builds don't include sm_120 kernels | `RuntimeError: sm_120 is not compatible` |
| 2 | **Never install xformers** | It force-downgrades PyTorch to stable | Everything stops working |
| 3 | **Exclude torch from requirements.txt** | pip will overwrite nightly with stable | Silent version downgrade |
| 4 | **Verify after adding custom nodes** | Node dependencies may pull in stable torch | Previously working setup breaks |
| 5 | **Clear proxy environment variables** | System proxies block pip/git connections | Installation failures |

---

## Verified Custom Nodes (28)

### Video Generation
- ComfyUI-WanVideoWrapper -- Wan 2.1 video generation
- ComfyUI-LTXVideo -- LTX-Video generation
- comfyui-videohelpersuite -- Video combine & helpers
- comfyui_longcat_image -- LongCat video processing

### Audio / Music Generation
- ComfyUI-AceMusic -- ACE-Step music generation
- ComfyUI-HeartMuLa -- HeartMuLa music generation
- ComfyUI-MelBandRoFormer -- Audio source separation
- ComfyUI_FL-HeartMuLa -- HeartMuLa FL variant

### Image Processing & Editing
- ComfyUI-Step1X-Edit -- Step1X image editing
- comfyui-impact-pack -- Detection & inpainting
- comfyui_controlnet_aux -- ControlNet preprocessors
- comfyui_layerstyle -- Layer compositing
- comfyui-depthanythingv2 -- Depth estimation

### Utility & Management
- ComfyUI-Manager -- Node management
- comfyui-kjnodes -- KJ utility nodes
- comfyui_essentials -- Essential utilities
- was-node-suite-comfyui -- WAS Node Suite
- ComfyUI_Comfyroll_CustomNodes -- Comfyroll collection
- rgthree-comfy -- Power tools
- efficiency-nodes-comfyui -- Efficient sampling
- masquerade-nodes-comfyui -- Mask manipulation
- comfyui-easy-use -- Simplified workflows
- comfyui-custom-scripts -- UI enhancements
- ComfyUI-Crystools -- System monitoring
- comfyui-quadmoons-nodes -- Quadmoons utilities
- ComfyUI_SimpleTranslator -- Text translation
- ComfyUI_kkTranslator_nodes -- Translation nodes
- ComfyUI-SKBundle -- SK bundle utilities

---

## Verified Image-to-Video Workflows

| Model | Parameters | FP8 Size | Performance on 32GB VRAM |
|-------|-----------|----------|--------------------------|
| HunyuanVideo 1.5 I2V | 8.3B | ~16GB | Smooth -- recommended |
| Kandinsky 5.0 Lite I2V | 2B | ~4GB | Very smooth |
| LTX-2 I2V | 19B | ~25GB | Works in FP8 |
| LongCat-Video TI2V | 13.6B | ~14.5GB | Works with adjustments |
| Kandinsky 5.0 Pro I2V | 19B | ~40GB | Requires CPU offload, slow |

---

## Windows-Specific Troubleshooting

### Model path errors (`Value not in list`)

Linux workflows use forward slashes (`/`) in model paths. Windows requires backslashes (`\`).

**Automatic fix:**
```powershell
python scripts/fix_windows_compat.py your_workflow.json
```

### SageAttention not available

SageAttention is difficult to build on Windows. Use SDPA (PyTorch native) instead:
- Change `attention_mode` from `sageattn` to `sdpa` in your workflow
- Or use `fix_windows_compat.py` to fix automatically

### torch.compile / Triton errors

triton-windows may not work perfectly in all scenarios. If you see Triton compilation errors:
- Disconnect `compile_args` from model loaders in your workflow
- RTX 5090 is fast enough without torch.compile for most workflows

### PyTorch was silently downgraded

After installing any package, always verify:
```powershell
python -c "import torch; print(torch.__version__)"
```
If it no longer contains `cu130`, reinstall:
```powershell
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu130
```

---

## Updating

Double-click `update.bat` or run:
```powershell
powershell -ExecutionPolicy Bypass -File update.ps1
```

This will update ComfyUI core, PyTorch, and all custom nodes while preserving Blackwell compatibility.

---

## FAQ

**Q: Do I need WSL2 or Docker?**
A: No. This setup runs entirely on Windows native. WSL2/Docker are alternatives but not required.

**Q: Can I use xformers?**
A: No. xformers forces a downgrade to PyTorch stable, which doesn't support sm_120. Use triton-windows + torch.compile instead.

**Q: Will this work on RTX 4090 (Ada Lovelace)?**
A: Yes. cu130 is backward-compatible. However, RTX 4090 users can also use stable PyTorch builds.

**Q: Where do I put models?**
A: After setup, place models in `ComfyUI_windows_portable/ComfyUI/models/`. See `configs/extra_model_paths.yaml.example` for shared model storage.

**Q: When will PyTorch stable support Blackwell?**
A: Expected in a future release (possibly PyTorch 2.12+). Until then, nightly cu130 is required.

---

## Contributing

Pull requests are welcome. If you've verified additional custom nodes or workflows on Blackwell hardware, please submit a PR to update `custom-nodes.json`.

---

## License

MIT License -- see [LICENSE](LICENSE)

---

## Acknowledgments

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) by Comfy-Org
- [triton-windows](https://github.com/woct0rdho/triton-windows) by woct0rdho
- [PyTorch](https://pytorch.org/) nightly team for sm_120 support
- All custom node developers listed in `custom-nodes.json`
