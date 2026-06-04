@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM ====================================================
REM   Claude Code 气隙启动器
REM   - 加载 .env 配置
REM   - 强制注入气隙隔离变量 (即使 .env 没设也保证安全)
REM   - 启动 claude.exe
REM ====================================================

REM ---- 1. 加载 .env ----
if not exist "%~dp0.env" (
  echo [ERROR] .env 不存在,请先从 .env.template 复制并填写
  echo         copy .env.template .env ^&^& notepad .env
  exit /b 1
)

for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0.env") do (
  set "LINE=%%a"
  if not "!LINE!"=="" set "%%a=%%b"
)

REM ---- 2. 关键变量检查 ----
if "!ANTHROPIC_BASE_URL!"=="" (
  echo [ERROR] ANTHROPIC_BASE_URL 未设置
  exit /b 1
)
if "!ANTHROPIC_AUTH_TOKEN!"=="" (
  echo [ERROR] ANTHROPIC_AUTH_TOKEN 未设置
  exit /b 1
)
if "!ANTHROPIC_MODEL!"=="" (
  echo [ERROR] ANTHROPIC_MODEL 未设置
  exit /b 1
)

REM ---- 3. 强制气隙隔离 (硬编码兜底,确保即使 .env 漏配也不触网) ----
REM     这些是 Claude Code 识别的官方 DISABLE 开关,=1 即可关闭对应功能
set DISABLE_AUTOUPDATER=1
set DISABLE_NONESSENTIAL_TRAFFIC=1
set DISABLE_ERROR_REPORTING=1
set DISABLE_TELEMETRY=1
set DISABLE_INSTALLATION_CHECKS=1
set DISABLE_GROWTHBOOK=1

REM ---- 4. 启动 Claude Code ----
"%~dp0claude.exe" %*
