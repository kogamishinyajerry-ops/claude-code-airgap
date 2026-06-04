@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"

call :msg RUN_TITLE
call :msg RUN_SUBTITLE
echo.

REM ---- 1.  .env ----
if not exist "%~dp0.env" (
  call :msg RUN_NO_ENV
  pause
  exit /b 1
)
for /f "usebackq tokens=1,2 delims==" %%a in ("%~dp0.env") do (
  set "%%a=%%b"
)

REM ---- 2.  ----
if "!ANTHROPIC_BASE_URL!"=="" (
  call :msg RUN_NO_URL
  exit /b 1
)
if "!ANTHROPIC_API_KEY!"=="" (
  call :msg RUN_NO_KEY
  exit /b 1
)
if "!ANTHROPIC_MODEL!"=="" (
  call :msg RUN_NO_MODEL
  exit /b 1
)

REM ---- 3.  (, .env ) ----
call :msg RUN_ISOLATE_HEADER
call :msg RUN_ISOLATE_NOTE
set "DISABLE_AUTOUPDATER=1"
set "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
set "DISABLE_ERROR_REPORTING=1"
set "DISABLE_TELEMETRY=1"
set "DISABLE_FEEDBACK_COMMAND=1"
set "DO_NOT_TRACK=1"
set "DISABLE_SUGGESTIONS=1"

REM ---- 4.  Claude Code ----
call :msg RUN_LAUNCH
"%~dp0claude.exe" %*
exit /b %ERRORLEVEL%


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
