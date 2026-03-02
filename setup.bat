@echo off
chcp 65001 >nul
title ComfyUI Blackwell Setup

echo.
echo ============================================================
echo   ComfyUI for GeForce RTX 50-series (Blackwell / sm_120)
echo   One-Click Setup
echo ============================================================
echo.
echo This will set up ComfyUI with full Blackwell GPU support.
echo.
echo Prerequisites:
echo   - NVIDIA Driver 580+ (for RTX 5090/5080/5070)
echo   - Git (https://git-scm.com/)
echo   - 7-Zip (https://7-zip.org/) for extraction
echo   - Internet connection (~2 GB download)
echo.
pause

powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

echo.
if %ERRORLEVEL% EQU 0 (
    echo Setup completed successfully!
    echo Run "run.bat" to start ComfyUI.
) else (
    echo Setup encountered errors. Please check the output above.
)
echo.
pause
