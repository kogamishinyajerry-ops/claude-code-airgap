@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"

call :msg DEPLOY_BORDER
call :msg DEPLOY_TITLE
call :msg DEPLOY_SUBTITLE
call :msg DEPLOY_BORDER
echo.

REM ---- 0.  () ----
call :msg STEP0_HEADER
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
  if exist "%~dp0install_deps.bat" (
    call :msg STEP0_DETECT
    call "%~dp0install_deps.bat"
  )
)

REM ---- 1.  ----
call :msg STEP1_HEADER
if not exist "%~dp0claude.exe" (
  call :msg STEP1_FATAL
  pause
  exit /b 1
)
call :msg STEP1_OK

REM ---- 2.  .env ----
call :msg STEP2_HEADER
if not exist "%~dp0.env" (
  call :msg STEP2_WARN
  call :msg STEP2_HINT
  call :msg PROMPT_CONTINUE_NO_ENV
  if /i not "!CONTINUE!"=="Y" (
    exit /b 1
  )
)
call :msg STEP2_INFO

REM  .env
for /f "usebackq tokens=1,2 delims==" %%a in ("%~dp0.env") do (
  set "%%a=%%b"
)

REM ---- 3.  ----
call :msg STEP3_HEADER
if "!ANTHROPIC_BASE_URL!"=="" (
  call :msg STEP3_NO_URL
  exit /b 1
)
if "!ANTHROPIC_API_KEY!"=="" (
  call :msg STEP3_NO_KEY
  exit /b 1
)
if "!ANTHROPIC_MODEL!"=="" (
  call :msg STEP3_NO_MODEL
  exit /b 1
)
call :msg STEP3_INFO_URL
echo         !ANTHROPIC_BASE_URL!
call :msg STEP3_INFO_MODEL
echo         !ANTHROPIC_MODEL!
call :msg STEP3_INFO_ISOLATE
echo         DISABLE_AUTOUPDATER=!DISABLE_AUTOUPDATER!  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=!CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC!

REM ---- 4.  New API  () ----
call :msg STEP4_HEADER
call :msg STEP4_PROBE
curl -s -o nul -w "HTTP Status: %%{http_code}\n" --max-time 5 "!ANTHROPIC_BASE_URL!/models" 2>nul
if %ERRORLEVEL%==0 (
  call :msg STEP4_OK
) else (
  call :msg STEP4_FAIL
)

REM ---- 5.  () ----
call :msg STEP5_HEADER
call :msg STEP5_CHECK
curl -s -o nul -w "HTTP Status: %%{http_code}\n" --max-time 3 "https://downloads.claude.ai/" 2>nul
if %ERRORLEVEL%==0 (
  call :msg STEP5_FAIL
  call :msg STEP5_FAIL_HINT
) else (
  call :msg STEP5_OK
)

REM ---- 6.  claude install (,) ----
call :msg STEP6_HEADER
call :msg STEP6_INTRO
call :msg STEP6_DESC1
call :msg STEP6_DESC2
echo.
call :msg PROMPT_DO_INSTALL
if /i "!DO_INSTALL!"=="Y" (
  call :msg STEP6_RUN
  "%~dp0claude.exe" install
  set RC=!ERRORLEVEL!
  if not "!RC!"=="0" (
    call :msg STEP6_WARN
    call :msg STEP6_WARN
  echo         !RC!,
  call :msg SETUP_RC_SUFFIX
  )
) else (
  call :msg STEP6_SKIP
)

echo.
call :msg DEPLOY_BORDER
call :msg DEPLOY_DONE_HEADER
call :msg DEPLOY_BORDER
call :msg DEPLOY_DONE_HINT1
call :msg DEPLOY_DONE_HINT2
call :msg DEPLOY_DONE_HINT3
call :msg DEPLOY_DONE_HINT4
echo.
call :msg DEPLOY_DONE_NOTE1
call :msg DEPLOY_DONE_NOTE2
echo.
call :msg DEPLOY_DONE_PRESS
pause >nul
exit /b 0


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
