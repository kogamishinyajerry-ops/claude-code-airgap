@echo off
REM 校验 claude.exe 的 SHA256 是否匹配官方 manifest
chcp 65001 >nul

set "EXPECTED=ac4e1319f6ac0c9e04336d0ae5845acc5dd317bf9e6f26ca47e63df06d91f8bc"

echo ============================================
echo   Claude Code 2.1.162 SHA256 校验
echo ============================================
echo.

if not exist "%~dp0claude.exe" (
  echo [FATAL] claude.exe 不存在
  exit /b 1
)

for /f "tokens=*" %%h in ('powershell -NoProfile -Command "Get-FileHash -Path '%~dp0claude.exe' -Algorithm SHA256 ^| Select-Object -ExpandProperty Hash"') do (
  set "ACTUAL=%%h"
)

echo 预期: %EXPECTED%
echo 实际: %ACTUAL%
echo.

if /i "%EXPECTED%"=="%ACTUAL%" (
  echo [OK] 校验通过
  exit /b 0
) else (
  echo [FAIL] 校验失败,文件可能损坏或被篡改
  exit /b 2
)
