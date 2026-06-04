@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

call :msg SETTINGS_HEADER
echo.

if not exist "claude_settings.json" (
  call :msg VERIFY_BIN_MISS
  exit /b 1
)

set "TARGET_DIR=%USERPROFILE%\.claude"
set "TARGET_FILE=%TARGET_DIR%\settings.json"

if not exist "%TARGET_DIR%" (
  mkdir "%TARGET_DIR%"
)

copy /Y "claude_settings.json" "%TARGET_FILE%" >nul
if %ERRORLEVEL%==0 (
  call :msg SETTINGS_OK
  echo         %TARGET_FILE%
  echo.
  call :msg SETTINGS_NOTE1
  call :msg SETTINGS_NOTE2
  exit /b 0
)
call :msg SETTINGS_FAIL
exit /b 1


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
