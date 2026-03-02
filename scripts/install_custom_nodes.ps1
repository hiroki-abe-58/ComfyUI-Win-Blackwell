#Requires -Version 5.1
<#
.SYNOPSIS
    Install verified custom nodes for ComfyUI on Blackwell.

.PARAMETER CustomNodesDir
    Path to ComfyUI's custom_nodes directory.

.PARAMETER JsonFile
    Path to custom-nodes.json. Defaults to ../custom-nodes.json relative to this script.

.PARAMETER RequiredOnly
    Only install nodes marked as "required": true.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CustomNodesDir,

    [string]$JsonFile,

    [switch]$RequiredOnly
)

$ErrorActionPreference = "Stop"

if (-not $JsonFile) {
    $JsonFile = Join-Path (Split-Path $PSScriptRoot -Parent) "custom-nodes.json"
}

if (-not (Test-Path $JsonFile)) {
    Write-Host "[ERROR] custom-nodes.json not found at: $JsonFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $CustomNodesDir)) {
    New-Item -ItemType Directory -Path $CustomNodesDir -Force | Out-Null
}

$config = Get-Content $JsonFile -Raw | ConvertFrom-Json
$nodes = $config.nodes

if ($RequiredOnly) {
    $nodes = $nodes | Where-Object { $_.required -eq $true }
}

$total = $nodes.Count
$current = 0
$succeeded = 0
$skipped = 0
$failed = 0

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Installing $total custom nodes..." -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

foreach ($node in $nodes) {
    $current++
    $targetDir = Join-Path $CustomNodesDir $node.name
    $pct = [math]::Round(($current / $total) * 100)

    Write-Host "[$current/$total] ($pct%) $($node.name)" -ForegroundColor White -NoNewline

    if (Test-Path $targetDir) {
        Write-Host " -- already installed, skipping" -ForegroundColor Gray
        $skipped++
        continue
    }

    try {
        git clone --depth 1 $node.url $targetDir 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " -- OK" -ForegroundColor Green

            # Install node-specific requirements if present
            $nodeReq = Join-Path $targetDir "requirements.txt"
            if (Test-Path $nodeReq) {
                # Find Python executable
                $pythonExe = $null
                $portableRoot = Split-Path (Split-Path $CustomNodesDir -Parent) -Parent
                $candidate = Join-Path $portableRoot "python_embeded\python.exe"
                if (Test-Path $candidate) {
                    $pythonExe = $candidate
                }

                if ($pythonExe) {
                    # Filter out torch-related packages to avoid downgrade
                    $filtered = Get-Content $nodeReq | Where-Object {
                        $_ -notmatch '^\s*#' -and
                        $_ -notmatch '^torch\b' -and
                        $_ -notmatch '^torchvision\b' -and
                        $_ -notmatch '^torchaudio\b' -and
                        $_ -notmatch 'xformers' -and
                        $_ -notmatch '^triton$'
                    }
                    if ($filtered) {
                        $tempReq = Join-Path $env:TEMP "cn_req_$($node.name).txt"
                        $filtered | Set-Content $tempReq
                        & $pythonExe -s -m pip install -r $tempReq --quiet 2>$null
                        Remove-Item $tempReq -ErrorAction SilentlyContinue
                    }
                }
            }

            $succeeded++
        } else {
            Write-Host " -- FAILED" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host " -- ERROR: $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Results: $succeeded installed, $skipped skipped, $failed failed" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan
