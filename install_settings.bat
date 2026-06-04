@echo off
chcp 65001 >nul
setlocal

REM 把 claude_settings.json 复制到用户配置目录
set "TARGET_DIR=%USERPROFILE%\.claude"
set "TARGET_FILE=%TARGET_DIR%\settings.json"

if not exist "%TARGET_DIR%" (
  mkdir "%TARGET_DIR%"
)

copy /Y "%~dp0claude_settings.json" "%TARGET_FILE%" >nul
if %ERRORLEVEL% neq 0 (
  echo [ERROR] 复制失败
  exit /b 1
)

echo [OK] 设置已写入 %TARGET_FILE%
echo.
echo 注: 实际生效的密钥仍以 .env 为准
echo     settings.json 提供默认模型名和权限策略
