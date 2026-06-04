@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ============================================
echo   Claude Code 依赖一键安装
echo   - Git for Windows 2.51.2
echo   - Visual C++ 2015-2022 Redistributable
echo ============================================
echo.

set "SCRIPT_DIR=%~dp0"
set "DEPS_DIR=%SCRIPT_DIR%dependencies"

REM 1. 安装 VC++ Redist (静默,无 UI)
if exist "%DEPS_DIR%\vc_redist.x64.exe" (
  echo [1/3] 安装 VC++ 2015-2022 Redistributable...
  "%DEPS_DIR%\vc_redist.x64.exe" /install /quiet /norestart
  if !ERRORLEVEL! equ 0 (
    echo       [OK]
  ) else if !ERRORLEVEL! equ 1638 (
    echo       [OK] 已安装(检测到现有版本)
  ) else (
    echo       [WARN] 安装返回码 !ERRORLEVEL!,可能需手动安装
  )
) else (
  echo [1/3] [SKIP] vc_redist.x64.exe 缺失
)

echo.

REM 2. 安装 Git (静默,Git Bash + 集成到 PATH)
if exist "%DEPS_DIR%\Git-2.51.2-64-bit.exe" (
  echo [2/3] 安装 Git for Windows 2.51.2...
  echo       (Git Bash 必需,Claude Code 依赖其运行)

  REM /SP- 取消欢迎页, /VERYSILENT 完全静默, /NORESTART 不重启
  "%DEPS_DIR%\Git-2.51.2-64-bit.exe" /SP- /VERYSILENT /NORESTART /CLOSEAPPLICATIONS ^
    /DIR="C:\Program Files\Git" ^
    /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh" ^
    /GROUP="Git" ^
    /TASKS="addtopath,gitbashhere,gitbashhereext,gitlfs"
  if !ERRORLEVEL! equ 0 (
    echo       [OK]
  ) else (
    echo       [WARN] 安装返回码 !ERRORLEVEL!,可手动双击安装
  )
) else (
  echo [2/3] [SKIP] Git-2.51.2-64-bit.exe 缺失
)

echo.

REM 3. 校验 PATH 中 git 可用
echo [3/3] 验证 Git...
where git >nul 2>nul
if !ERRORLEVEL! equ 0 (
  for /f "tokens=*" %%v in ('git --version') do echo       [OK] %%v
) else (
  echo       [WARN] git 不在 PATH,需重启 PowerShell 窗口
)

echo.
echo ============================================
echo   依赖安装完成
echo   下一步: 回到 ..\ 目录运行 setup.bat
echo ============================================
pause
