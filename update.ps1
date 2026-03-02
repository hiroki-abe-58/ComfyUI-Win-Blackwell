#Requires -Version 5.1
<#
.SYNOPSIS
    Update ComfyUI and dependencies for Blackwell GPU environment.

.DESCRIPTION
    Updates ComfyUI core, PyTorch cu130, and custom nodes while preserving
    Blackwell compatibility (nightly cu130, no xformers).

.PARAMETER SkipPyTorch
    Skip PyTorch update (useful if current version works fine).

.PARAMETER SkipCustomNodes
    Skip custom node updates.
#>

param(
    [switch]$SkipPyTorch,
    [switch]$SkipCustomNodes
)

$ErrorActionPreference = "Stop"

# Clear proxy
$env:ALL_PROXY = ''; $env:HTTP_PROXY = ''; $env:HTTPS_PROXY = ''

# Locate ComfyUI
$scriptDir = $PSScriptRoot
$comfyRoot = $null
if (Test-Path (Join-Path $scriptDir "ComfyUI_windows_portable\ComfyUI\main.py")) {
    $comfyRoot = Join-Path $scriptDir "ComfyUI_windows_portable"
} elseif (Test-Path (Join-Path $scriptDir "ComfyUI\main.py")) {
    $comfyRoot = $scriptDir
}

if (-not $comfyRoot) {
    Write-Host "[ERROR] ComfyUI installation not found." -ForegroundColor Red
    exit 1
}

$pythonExe = Join-Path $comfyRoot "python_embeded\python.exe"

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  ComfyUI Blackwell Update" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# --- 1. Update ComfyUI core ---
Write-Host "[1/3] Updating ComfyUI core..." -ForegroundColor Yellow
$comfyDir = Join-Path $comfyRoot "ComfyUI"
Push-Location $comfyDir
try {
    git pull origin main
    Write-Host "  [OK] ComfyUI updated." -ForegroundColor Green
} catch {
    Write-Host "  [WARN] git pull failed: $_" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# --- 2. Update PyTorch cu130 ---
if ($SkipPyTorch) {
    Write-Host "[2/3] Skipping PyTorch update." -ForegroundColor Gray
} else {
    Write-Host "[2/3] Updating PyTorch cu130..." -ForegroundColor Yellow

    $currentVer = & $pythonExe -s -c "import torch; print(torch.__version__)" 2>$null
    Write-Host "  Current: $currentVer" -ForegroundColor Gray

    & $pythonExe -s -m pip install --pre torch torchvision torchaudio `
        --index-url https://download.pytorch.org/whl/nightly/cu130 `
        --upgrade

    $newVer = & $pythonExe -s -c "import torch; print(torch.__version__)" 2>$null
    Write-Host "  Updated: $newVer" -ForegroundColor Green

    # Verify it's still nightly/cu130
    $cudaVer = & $pythonExe -s -c "import torch; print(torch.version.cuda)" 2>$null
    if ($cudaVer -notlike "13.*" -and $cudaVer -notlike "12.8*") {
        Write-Host "  [WARN] CUDA version $cudaVer -- expected 13.x or 12.8" -ForegroundColor Yellow
    }

    # Reinstall triton-windows (may need matching version)
    & $pythonExe -s -m pip install "triton-windows<3.7" --upgrade 2>$null
}

# --- 3. Update custom nodes ---
if ($SkipCustomNodes) {
    Write-Host "[3/3] Skipping custom node updates." -ForegroundColor Gray
} else {
    Write-Host "[3/3] Updating custom nodes..." -ForegroundColor Yellow
    $cnDir = Join-Path $comfyRoot "ComfyUI\custom_nodes"
    if (Test-Path $cnDir) {
        $nodes = Get-ChildItem $cnDir -Directory | Where-Object {
            Test-Path (Join-Path $_.FullName ".git")
        }
        foreach ($node in $nodes) {
            Write-Host "  Updating $($node.Name)..." -ForegroundColor Gray -NoNewline
            Push-Location $node.FullName
            try {
                git pull --quiet 2>$null
                Write-Host " OK" -ForegroundColor Green
            } catch {
                Write-Host " SKIP" -ForegroundColor Yellow
            } finally {
                Pop-Location
            }
        }
    }
}

# --- Verify ---
Write-Host "`n--- Verification ---" -ForegroundColor Cyan
& $pythonExe -s -c @"
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA: {torch.version.cuda}')
print(f'GPU Available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
"@

Write-Host "`n[OK] Update complete.`n" -ForegroundColor Green
