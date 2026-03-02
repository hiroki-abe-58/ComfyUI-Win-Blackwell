@echo off
chcp 65001 >nul
title ComfyUI Blackwell Update

echo.
echo ============================================
echo   ComfyUI Blackwell Update
echo ============================================
echo.
echo This will update ComfyUI, PyTorch, and custom nodes.
echo Your models and outputs will NOT be affected.
echo.
pause

powershell -ExecutionPolicy Bypass -File "%~dp0update.ps1"

echo.
pause
