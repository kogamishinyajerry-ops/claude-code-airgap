@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ============================================
echo   Claude Code 2.1.162 内网气隙部署
echo   Target: Windows x64 + New API (气隙隔离)
echo ============================================
echo.

REM ---- 0. 先装依赖(如果未装) ----
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
  if exist "%~dp0install_deps.bat" (
    echo [INFO] 检测到 Git 未安装,先运行依赖安装...
    call "%~dp0install_deps.bat"
  )
)

REM ---- 1. 校验二进制 ----
if not exist "%~dp0claude.exe" (
  echo [FATAL] claude.exe 不存在,中止
  pause
  exit /b 1
)

REM ---- 2. 校验 .env ----
if not exist "%~dp0.env" (
  echo [WARN] .env 不存在
  echo        请先复制 .env.template 为 .env 并填入 New API 地址/Key
  echo.
  set /p CONTINUE="按 Y 继续(不推荐),其他键退出: "
  if /i not "!CONTINUE!"=="Y" exit /b 2
) else (
  echo [INFO] 加载 .env ...
  for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0.env") do (
    set "LINE=%%a"
    if not "!LINE!"=="" set "%%a=%%b"
  )
)

REM ---- 3. 关键变量检查 ----
if "!ANTHROPIC_BASE_URL!"=="" (
  echo [FATAL] ANTHROPIC_BASE_URL 未设置
  pause
  exit /b 3
)
if "!ANTHROPIC_AUTH_TOKEN!"=="" (
  echo [FATAL] ANTHROPIC_AUTH_TOKEN 未设置
  pause
  exit /b 3
)
if "!ANTHROPIC_MODEL!"=="" (
  echo [FATAL] ANTHROPIC_MODEL 未设置
  pause
  exit /b 3
)

echo [INFO] 目标 New API: !ANTHROPIC_BASE_URL!
echo [INFO] 模型:         !ANTHROPIC_MODEL!
echo [INFO] 隔离模式:     DISABLE_AUTOUPDATER=!DISABLE_AUTOUPDATER!  DISABLE_NONESSENTIAL_TRAFFIC=!DISABLE_NONESSENTIAL_TRAFFIC!
echo.

REM ---- 4. 探测 New API 可达性 (内网) ----
echo [INFO] 探测 New API 连通性 (内网)...
powershell -NoProfile -Command ^
  "try { $r = Invoke-WebRequest -Uri '!ANTHROPIC_BASE_URL!/../' -UseBasicParsing -TimeoutSec 5 -Method HEAD -ErrorAction Stop; Write-Host '  [OK] HTTP ' $r.StatusCode } catch { Write-Host '  [WARN] 无法直接探测 (正常,HEAD 可能被拒). 继续' }"
echo.

REM ---- 5. 验证外网已隔离 (可选) ----
echo [INFO] 验证外网已隔离...
powershell -NoProfile -Command ^
  "try { $r = Invoke-WebRequest -Uri 'https://downloads.claude.ai/' -UseBasicParsing -TimeoutSec 3 -Method HEAD -ErrorAction Stop; Write-Host '  [WARN] 仍可访问外网,请检查 .env 的 DISABLE_* 变量是否被加载' } catch { Write-Host '  [OK] 外网不可达,符合气隙部署预期' }"
echo.

REM ---- 6. 执行 claude install (非必需,可跳过) ----
echo [INFO] 关于 shell 集成 (claude install):
echo        该命令注册 Windows 右键菜单 / PowerShell 补全,非必需
echo        在气隙环境 claude install 可能失败,但 run.bat 不依赖它
echo.
set /p DO_INSTALL="是否执行 claude install 试试? (y/N): "
if /i "!DO_INSTALL!"=="Y" (
  echo [INFO] 调用 claude.exe install (可能因外网隔离失败,正常)...
  "%~dp0claude.exe" install
  set RC=!ERRORLEVEL!
  if not "!RC!"=="0" (
    echo [WARN] install 返回码 !RC!,不影响使用,继续
  )
) else (
  echo [SKIP] 已跳过 install,直接用 run.bat 即可
)

echo.
echo ============================================
echo   部署完成
echo.
echo   启动:  run.bat              (日常用)
echo   配置:  install_settings.bat (推送 settings.json)
echo   卸载:  uninstall.bat
echo.
echo   注意: 当前是气隙模式,不会触碰外网
echo         .env 中所有 DISABLE_*=1 会被 run.bat 自动加载
echo ============================================
pause
