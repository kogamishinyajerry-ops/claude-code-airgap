@echo off
chcp 65001 >nul

echo ============================================
echo   Claude Code 卸载脚本
echo ============================================
echo.

set /p CONFIRM="确认卸载 Claude Code? (y/N): "
if /i not "%CONFIRM%"=="y" (
  echo 已取消
  exit /b 0
)

REM 防御: claude.exe 不在时 (例如只删了 exe 但保留脚本) 不报错
if not exist "%~dp0claude.exe" (
  echo [WARN] claude.exe 不在 %~dp0,无需卸载
  echo        如需清理 PATH / 右键菜单集成,请手动操作
  exit /b 0
)

"%~dp0claude.exe" uninstall

set "RC=%ERRORLEVEL%"
if "%RC%"=="0" (
  echo.
  echo [OK] 已卸载
  echo 如需删除本地配置,手动删除: %USERPROFILE%\.claude\
) else (
  echo [WARN] 卸载返回码: %RC%
)
pause
