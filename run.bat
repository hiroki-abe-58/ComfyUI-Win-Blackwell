@echo off
chcp 65001 >nul
title ComfyUI - Blackwell

:start
echo ========================================
echo ComfyUI Starting... (Blackwell Mode)
echo ========================================
echo.

REM Kill process using port 8188
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8188 ^| findstr LISTENING 2^>nul') do (
    echo Killing process %%a on port 8188...
    taskkill /F /PID %%a >nul 2>&1
)

REM Clear proxy (common pitfall on Windows)
set ALL_PROXY=
set HTTP_PROXY=
set HTTPS_PROXY=

REM Optimize for Blackwell GPU
set PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
set CUDA_VISIBLE_DEVICES=0

REM Locate ComfyUI portable directory
if exist "%~dp0ComfyUI_windows_portable\python_embeded\python.exe" (
    set "COMFY_ROOT=%~dp0ComfyUI_windows_portable"
) else if exist "%~dp0python_embeded\python.exe" (
    set "COMFY_ROOT=%~dp0"
) else (
    echo ERROR: ComfyUI installation not found.
    echo Please run setup.bat first.
    pause
    exit /b 1
)

"%COMFY_ROOT%\python_embeded\python.exe" -s "%COMFY_ROOT%\ComfyUI\main.py" --windows-standalone-build --highvram

echo.
echo ========================================
echo ComfyUI stopped (Exit code: %ERRORLEVEL%)
echo ========================================
echo.
echo [R] Restart  [Q] Quit
echo.

choice /C RQ /N /M "Select: "
if errorlevel 2 goto end
if errorlevel 1 goto start

:end
echo Closing ComfyUI...
