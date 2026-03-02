#Requires -Version 5.1
<#
.SYNOPSIS
    ComfyUI setup script for NVIDIA GeForce RTX 50-series (Blackwell / sm_120) on Windows.

.DESCRIPTION
    Automates the full installation of ComfyUI with Blackwell GPU support:
      1. Prerequisite checks (Python, NVIDIA driver, Git)
      2. ComfyUI Portable download & extraction
      3. PyTorch cu130 (CUDA 13.0) installation into embedded Python
      4. triton-windows installation
      5. Core dependency installation
      6. Verified custom node cloning
      7. Environment verification

.PARAMETER InstallDir
    Target installation directory. Defaults to .\ComfyUI_windows_portable

.PARAMETER SkipCustomNodes
    Skip custom node installation.

.PARAMETER SkipVerify
    Skip environment verification after setup.

.EXAMPLE
    .\setup.ps1
    .\setup.ps1 -InstallDir "D:\AI\ComfyUI"
#>

param(
    [string]$InstallDir = ".\ComfyUI_windows_portable",
    [switch]$SkipCustomNodes,
    [switch]$SkipVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "`n[$Step] $Message" -ForegroundColor Cyan
}

function Write-Ok   { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  [ERROR] $Msg" -ForegroundColor Red }

function Test-CommandExists {
    param([string]$Cmd)
    $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  ComfyUI for GeForce RTX 50-series (Blackwell / sm_120)"   -ForegroundColor Magenta
Write-Host "  Windows Native Setup"                                       -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Clear proxy (common pitfall)
# ---------------------------------------------------------------------------
Write-Step "1/8" "Clearing proxy environment variables..."
$env:ALL_PROXY   = ''
$env:HTTP_PROXY  = ''
$env:HTTPS_PROXY = ''
$env:GIT_HTTP_PROXY  = ''
$env:GIT_HTTPS_PROXY = ''
Write-Ok "Proxy variables cleared."

# ---------------------------------------------------------------------------
# 2. Prerequisite checks
# ---------------------------------------------------------------------------
Write-Step "2/8" "Checking prerequisites..."

# Git
if (-not (Test-CommandExists "git")) {
    Write-Err "Git is not installed."
    Write-Host "  Install: winget install Git.Git" -ForegroundColor Yellow
    Write-Host "  Then restart your terminal and run this script again."
    exit 1
}
$gitVer = git --version
Write-Ok "Git: $gitVer"

# NVIDIA driver
if (-not (Test-CommandExists "nvidia-smi")) {
    Write-Err "nvidia-smi not found. Please install NVIDIA drivers (580+)."
    exit 1
}

$driverLine = nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>$null
if ($driverLine) {
    $driverVer = [float]$driverLine.Trim()
    if ($driverVer -lt 580) {
        Write-Err "NVIDIA driver $driverVer is too old. Version 580+ required for Blackwell."
        Write-Host "  Download: https://www.nvidia.com/drivers" -ForegroundColor Yellow
        exit 1
    }
    Write-Ok "NVIDIA Driver: $driverVer"
} else {
    Write-Warn "Could not query driver version. Continuing..."
}

$gpuName = (nvidia-smi --query-gpu=name --format=csv,noheader 2>$null)
if ($gpuName) { Write-Ok "GPU: $($gpuName.Trim())" }

# ---------------------------------------------------------------------------
# 3. Download ComfyUI Portable
# ---------------------------------------------------------------------------
Write-Step "3/8" "Setting up ComfyUI..."

$resolvedDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InstallDir)

if (Test-Path (Join-Path $resolvedDir "ComfyUI\main.py")) {
    Write-Ok "ComfyUI already exists at $resolvedDir. Skipping download."
} else {
    Write-Host "  Downloading ComfyUI Windows Portable..." -ForegroundColor White
    Write-Host "  This may take several minutes depending on your connection." -ForegroundColor Gray

    $tempZip = Join-Path $env:TEMP "ComfyUI_windows_portable.7z"
    $downloadUrl = "https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z"

    try {
        if (Test-CommandExists "curl.exe") {
            curl.exe -L -C - --progress-bar -o $tempZip $downloadUrl
        } else {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        }
    } catch {
        Write-Err "Download failed: $_"
        Write-Host "  Please download manually from:" -ForegroundColor Yellow
        Write-Host "  https://github.com/comfyanonymous/ComfyUI/releases" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "  Extracting..." -ForegroundColor White
    if (Test-CommandExists "7z") {
        7z x $tempZip -o"$(Split-Path $resolvedDir -Parent)" -y
    } else {
        Write-Err "7-Zip (7z) is not installed. Please install it or extract manually."
        Write-Host "  Install: winget install 7zip.7zip" -ForegroundColor Yellow
        Write-Host "  Then extract $tempZip to $(Split-Path $resolvedDir -Parent)" -ForegroundColor Yellow
        exit 1
    }

    Remove-Item $tempZip -ErrorAction SilentlyContinue
    Write-Ok "ComfyUI extracted to $resolvedDir"
}

$comfyRoot = $resolvedDir
$pythonExe = Join-Path $comfyRoot "python_embeded\python.exe"
$pipCmd    = Join-Path $comfyRoot "python_embeded\python.exe"

if (-not (Test-Path $pythonExe)) {
    Write-Err "Embedded Python not found at $pythonExe"
    exit 1
}

$pyVer = & $pythonExe --version 2>&1
Write-Ok "Embedded Python: $pyVer"

# ---------------------------------------------------------------------------
# 4. Install PyTorch cu130 (CUDA 13.0) -- CRITICAL STEP
# ---------------------------------------------------------------------------
Write-Step "4/8" "Installing PyTorch with CUDA 13.0 (cu130)..."
Write-Host "  This is the most important step for Blackwell GPU support." -ForegroundColor Yellow
Write-Host "  Download size: ~1.9 GB. Please be patient." -ForegroundColor Gray

& $pipCmd -s -m pip install --upgrade pip 2>$null

& $pipCmd -s -m pip install --pre torch torchvision torchaudio `
    --index-url https://download.pytorch.org/whl/nightly/cu130 `
    --force-reinstall

if ($LASTEXITCODE -ne 0) {
    Write-Err "PyTorch installation failed."
    Write-Host "  Check your network connection and try again." -ForegroundColor Yellow
    exit 1
}

$torchVer = & $pipCmd -s -c "import torch; print(torch.__version__)" 2>$null
Write-Ok "PyTorch: $torchVer"

# ---------------------------------------------------------------------------
# 5. Install triton-windows
# ---------------------------------------------------------------------------
Write-Step "5/8" "Installing triton-windows..."

& $pipCmd -s -m pip install "triton-windows<3.7"

if ($LASTEXITCODE -eq 0) {
    Write-Ok "triton-windows installed."
} else {
    Write-Warn "triton-windows installation failed. torch.compile may not work, but ComfyUI will still run."
}

# ---------------------------------------------------------------------------
# 6. Install core dependencies
# ---------------------------------------------------------------------------
Write-Step "6/8" "Installing core dependencies..."

$reqFile = Join-Path $PSScriptRoot "requirements-core.txt"
if (Test-Path $reqFile) {
    & $pipCmd -s -m pip install -r $reqFile
    Write-Ok "Core dependencies installed."
} else {
    Write-Warn "requirements-core.txt not found. Installing from ComfyUI's requirements.txt..."
    $comfyReq = Join-Path $comfyRoot "ComfyUI\requirements.txt"
    if (Test-Path $comfyReq) {
        $filtered = Get-Content $comfyReq | Where-Object {
            $_ -notmatch '^\s*#' -and
            $_ -notmatch '^torch\b' -and
            $_ -notmatch '^torchvision\b' -and
            $_ -notmatch '^torchaudio\b' -and
            $_ -notmatch 'xformers'
        }
        $tempReq = Join-Path $env:TEMP "comfyui_req_filtered.txt"
        $filtered | Set-Content $tempReq
        & $pipCmd -s -m pip install -r $tempReq
        Remove-Item $tempReq -ErrorAction SilentlyContinue
    }
    Write-Ok "Dependencies installed."
}

# ---------------------------------------------------------------------------
# 7. Install custom nodes
# ---------------------------------------------------------------------------
Write-Step "7/8" "Installing custom nodes..."

if ($SkipCustomNodes) {
    Write-Warn "Skipped (--SkipCustomNodes flag)."
} else {
    $cnScript = Join-Path $PSScriptRoot "scripts\install_custom_nodes.ps1"
    $cnDir = Join-Path $comfyRoot "ComfyUI\custom_nodes"

    if (Test-Path $cnScript) {
        & $cnScript -CustomNodesDir $cnDir
    } else {
        Write-Warn "install_custom_nodes.ps1 not found. Skipping custom node installation."
        Write-Host "  You can install them later via ComfyUI Manager." -ForegroundColor Gray
    }
}

# ---------------------------------------------------------------------------
# 8. Verify environment
# ---------------------------------------------------------------------------
Write-Step "8/8" "Verifying environment..."

if ($SkipVerify) {
    Write-Warn "Skipped (--SkipVerify flag)."
} else {
    $verifyScript = Join-Path $PSScriptRoot "verify_env.py"
    if (Test-Path $verifyScript) {
        & $pythonExe -s $verifyScript
    } else {
        & $pythonExe -s -c @"
import torch
print('PyTorch:', torch.__version__)
print('CUDA:', torch.version.cuda)
print('Available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('GPU:', torch.cuda.get_device_name(0))
    cap = torch.cuda.get_device_capability(0)
    print(f'Compute Capability: sm_{cap[0]}{cap[1]}0')
"@
    }
}

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  To start ComfyUI:" -ForegroundColor White
Write-Host "    .\run.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Or manually:" -ForegroundColor White
Write-Host "    cd $comfyRoot" -ForegroundColor Yellow
Write-Host "    .\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Access: http://localhost:8188" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Download models to: $comfyRoot\ComfyUI\models\" -ForegroundColor Gray
Write-Host "    2. Place checkpoints in: $comfyRoot\ComfyUI\models\checkpoints\" -ForegroundColor Gray
Write-Host "    3. Place LoRAs in: $comfyRoot\ComfyUI\models\loras\" -ForegroundColor Gray
Write-Host ""
