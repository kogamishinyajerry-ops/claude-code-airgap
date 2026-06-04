@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

call :msg DEPLOY_BORDER
call :msg UNINSTALL_TITLE
call :msg DEPLOY_BORDER
echo.

call :msg UNINSTALL_CONFIRM
if /i not "%CONFIRM%"=="Y" (
  call :msg UNINSTALL_CANCEL
  exit /b 0
)

REM 防御: claude.exe 不在时 (例如只删了 exe 但保留脚本) 不报错
if not exist "%~dp0claude.exe" (
  call :msg UNINSTALL_DEFEND
  echo         %~dp0
  call :msg UNINSTALL_DEFEND_NOTE
  exit /b 0
)

"%~dp0claude.exe" uninstall
set RC=%ERRORLEVEL%
if %RC%==0 (
  call :msg UNINSTALL_OK
  call :msg UNINSTALL_NOTE
  echo         %USERPROFILE%\.claude\
  exit /b 0
)
call :msg UNINSTALL_WARN
echo         %RC%
exit /b %RC%


REM ===== Sub: print message line from messages\zh.txt by [LABEL] =====
:msg
setlocal
for /f "tokens=1* delims=]" %%a in ('findstr /B /C:"[%~1]" "messages\zh.txt" 2^>nul') do (
    endlocal
    echo %%b
    goto :eof
)
endlocal
goto :eof
