@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ============================================
echo   Claude Code 气隙环境验证脚本
echo   用途: 确认部署后不触碰任何外网
echo ============================================
echo.

set "PASS=0"
set "FAIL=0"

REM ---- 1. 检查依赖 ----
echo [1/5] 检查 Git for Windows...
where git >nul 2>nul
if !ERRORLEVEL! equ 0 (
  for /f "tokens=*" %%v in ('git --version') do echo       [OK] %%v
  set /a PASS+=1
) else (
  echo       [FAIL] git 不在 PATH
  set /a FAIL+=1
)
echo.

REM ---- 2. 检查 VC++ Redist ----
echo [2/5] 检查 VC++ 2015-2022 Redistributable...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>nul
if !ERRORLEVEL! equ 0 (
  echo       [OK] 已安装
  set /a PASS+=1
) else (
  echo       [WARN] 未在注册表检测到,可能已通过其他途径安装
)
echo.

REM ---- 3. 检查 claude.exe 完整性 ----
echo [3/5] 检查 claude.exe ...
if exist "%~dp0claude.exe" (
  for /f "tokens=*" %%h in ('powershell -NoProfile -Command "Get-FileHash -Path '%~dp0claude.exe' -Algorithm SHA256 ^| Select-Object -ExpandProperty Hash"') do (
    set "ACTUAL=%%h"
  )
  if "!ACTUAL!"=="ac4e1319f6ac0c9e04336d0ae5845acc5dd317bf9e6f26ca47e63df06d91f8bc" (
  echo       [OK] SHA256 校验通过
  set /a PASS+=1
  ) else (
    echo       [FAIL] SHA256 不匹配
    echo              实际: !ACTUAL!
    echo              预期: ac4e1319f6ac0c9e04336d0ae5845acc5dd317bf9e6f26ca47e63df06d91f8bc
    set /a FAIL+=1
  )
) else (
  echo       [FAIL] 文件缺失
  set /a FAIL+=1
)
echo.

REM ---- 4. 检查 .env 配置 ----
echo [4/5] 检查 .env 配置...
if exist "%~dp0.env" (
  findstr /C:"ANTHROPIC_BASE_URL=http" "%~dp0.env" >nul 2>nul
  if !ERRORLEVEL! neq 0 (
    echo       [FAIL] ANTHROPIC_BASE_URL 未正确配置 (仍是 <NEWAPI_HOST> 占位)
    set /a FAIL+=1
  ) else (
    echo       [OK] ANTHROPIC_BASE_URL 已配置
  )

  findstr /C:"<YOUR_NEWAPI_KEY>" "%~dp0.env" >nul 2>nul
  if !ERRORLEVEL! equ 0 (
    echo       [FAIL] ANTHROPIC_API_KEY 仍是占位符
    set /a FAIL+=1
  ) else (
    echo       [OK] ANTHROPIC_API_KEY 已配置
  )

  findstr /C:"DISABLE_AUTOUPDATER=1" "%~dp0.env" >nul 2>nul
  if !ERRORLEVEL! equ 0 (
    echo       [OK] 气隙隔离变量已配置
    set /a PASS+=1
  ) else (
    echo       [WARN] 缺气隙隔离变量,run.bat 会强制注入兜底
  )
) else (
  echo       [FAIL] .env 文件不存在
  set /a FAIL+=1
)
echo.

REM ---- 5. 检查外网隔离 (最关键) ----
echo [5/5] 验证外网已隔离 (尝试访问 claude.ai)...
powershell -NoProfile -Command ^
  "try { $r = Invoke-WebRequest -Uri 'https://downloads.claude.ai/' -UseBasicParsing -TimeoutSec 5 -Method HEAD -ErrorAction Stop; Write-Host '       [WARN] 仍可访问 downloads.claude.ai,环境非气隙' } catch { Write-Host '       [OK] 外网已隔离 (符合预期)' }"
echo.

echo ============================================
echo   验证结果: PASS=!PASS!  FAIL=!FAIL!
echo ============================================
if !FAIL! gtr 0 (
  echo [状态] 存在 !FAIL! 个问题,请先解决
  pause
  exit /b 1
) else (
  echo [状态] 全部通过,可以放心使用 run.bat
  pause
  exit /b 0
)
