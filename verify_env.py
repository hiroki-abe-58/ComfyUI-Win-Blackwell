"""
Blackwell (sm_120) Environment Verification Script

Validates that the current environment is correctly configured for
NVIDIA GeForce RTX 50-series GPUs on Windows.

Usage:
    ComfyUI_windows_portable\python_embeded\python.exe -s verify_env.py
"""

import sys
import subprocess
import importlib


def header(title: str) -> None:
    print(f"\n{'=' * 60}")
    print(f"  {title}")
    print(f"{'=' * 60}")


def ok(msg: str) -> None:
    print(f"  [OK]   {msg}")


def warn(msg: str) -> None:
    print(f"  [WARN] {msg}")


def fail(msg: str) -> None:
    print(f"  [FAIL] {msg}")


def check_python() -> bool:
    header("Python")
    v = sys.version_info
    version_str = f"{v.major}.{v.minor}.{v.micro}"
    passed = v >= (3, 12)
    (ok if passed else fail)(f"Version: {version_str}  (3.12+ required)")
    ok(f"Path: {sys.executable}")
    return passed


def check_nvidia_driver() -> bool:
    header("NVIDIA Driver")
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=driver_version,name",
             "--format=csv,noheader"],
            capture_output=True, text=True, timeout=10,
        )
        if result.returncode != 0:
            fail("nvidia-smi returned an error")
            return False

        parts = result.stdout.strip().split(", ")
        driver = parts[0]
        gpu = parts[1] if len(parts) > 1 else "unknown"
        driver_ok = float(driver) >= 580
        (ok if driver_ok else fail)(f"Driver: {driver}  (580+ required)")
        ok(f"GPU: {gpu}")
        return driver_ok
    except FileNotFoundError:
        fail("nvidia-smi not found")
        return False
    except Exception as e:
        fail(f"nvidia-smi error: {e}")
        return False


def check_pytorch() -> bool:
    header("PyTorch")
    try:
        import torch
    except ImportError:
        fail("PyTorch is not installed")
        return False

    version = torch.__version__
    cuda_version = torch.version.cuda or "N/A"
    cuda_available = torch.cuda.is_available()

    is_cu130 = "cu130" in version or cuda_version.startswith("13.")
    is_cu128 = "cu128" in version or cuda_version.startswith("12.8")
    cuda_ok = is_cu130 or is_cu128

    (ok if cuda_ok else fail)(f"Version: {version}")
    (ok if cuda_ok else fail)(f"CUDA: {cuda_version}")
    (ok if cuda_available else fail)(f"CUDA Available: {cuda_available}")

    if not cuda_available:
        return False

    gpu_name = torch.cuda.get_device_name(0)
    cap = torch.cuda.get_device_capability(0)
    props = torch.cuda.get_device_properties(0)
    vram_gb = props.total_memory / (1024 ** 3)

    is_blackwell = cap[0] >= 12
    ok(f"GPU: {gpu_name}")
    (ok if is_blackwell else warn)(f"Compute Capability: sm_{cap[0]}{cap[1]}0")
    ok(f"VRAM: {vram_gb:.1f} GB")

    # Tensor operation test
    try:
        x = torch.randn(256, 256, device="cuda")
        y = torch.matmul(x, x)
        del x, y
        torch.cuda.empty_cache()
        ok("CUDA tensor test: PASSED")
    except Exception as e:
        fail(f"CUDA tensor test: FAILED ({e})")
        return False

    return True


def check_triton() -> bool:
    header("Triton (torch.compile support)")
    try:
        import triton
        ok(f"triton-windows: {triton.__version__}")
        return True
    except ImportError:
        warn("triton-windows not installed (optional, torch.compile won't work)")
        return True  # not a hard requirement


def check_core_packages() -> bool:
    header("Core Packages")
    packages = [
        "torchsde", "einops", "transformers", "tokenizers",
        "sentencepiece", "safetensors", "aiohttp", "pyyaml",
        "PIL", "scipy", "tqdm", "psutil", "kornia", "spandrel",
        "pydantic", "av",
    ]
    all_ok = True
    for pkg in packages:
        try:
            importlib.import_module(pkg)
            ok(pkg)
        except ImportError:
            warn(f"{pkg} -- not installed")
            all_ok = False
    return all_ok


def check_torch_compile() -> bool:
    header("torch.compile (optional)")
    try:
        import torch
        model = torch.nn.Linear(16, 16).cuda()
        compiled = torch.compile(model, backend="inductor")
        x = torch.randn(4, 16, device="cuda")
        _ = compiled(x)
        ok("torch.compile (inductor): PASSED")
        return True
    except Exception as e:
        warn(f"torch.compile: {e}")
        warn("This is optional -- eager mode still works fine.")
        return True


def main() -> int:
    print()
    print("=" * 60)
    print("  Blackwell (sm_120) Environment Verification")
    print("  For NVIDIA GeForce RTX 50-series on Windows")
    print("=" * 60)

    results = {
        "Python": check_python(),
        "NVIDIA Driver": check_nvidia_driver(),
        "PyTorch": check_pytorch(),
        "Triton": check_triton(),
        "Core Packages": check_core_packages(),
        "torch.compile": check_torch_compile(),
    }

    header("Summary")
    all_passed = True
    for name, passed in results.items():
        status = "[OK]" if passed else "[FAIL]"
        color_mark = status
        print(f"  {color_mark}  {name}")
        if not passed:
            all_passed = False

    print()
    print("=" * 60)
    if all_passed:
        print("  Environment is ready for Blackwell GPU!")
        print("  Run ComfyUI with: run.bat")
    else:
        print("  Some checks failed. Review the output above.")
    print("=" * 60)
    print()

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
