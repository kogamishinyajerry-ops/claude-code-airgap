@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"

call :msg DEPLOY_BORDER
call :msg VERIFY_TITLE
call :msg VERIFY_SUBTITLE
call :msg DEPLOY_BORDER
echo.

set PASS=0
set FAIL=0

REM ---- 1. 检查依赖 ----
call :msg VERIFY_DEP_GIT
where git >nul 2>nul
if %ERRORLEVEL%==0 (
  call :msg VERIFY_DEP_GIT_OK
  set /a PASS+=1
) else (
  call :msg VERIFY_DEP_GIT_FAIL
  set /a FAIL+=1
)

REM ---- 2. 检查 VC++ Redist ----
call :msg VERIFY_DEP_VC
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>nul
if %ERRORLEVEL%==0 (
  call :msg VERIFY_DEP_VC_OK
  set /a PASS+=1
) else (
  call :msg VERIFY_DEP_VC_WARN
)

REM ---- 3. 检查 claude.exe 完整性 ----
call :msg VERIFY_BIN
if exist "%~dp0claude.exe" (
  set EXPECTED=ac4e1319f6ac0c9e04336d0ae5845acc5dd317bf9e6f26ca47e63df06d91f8bc
  for /f %%h in ('certutil -hashfile "%~dp0claude.exe" SHA256 ^| findstr /v "certutil"') do set "ACTUAL=%%h"
  if /i "!ACTUAL!"=="!EXPECTED!" (
    call :msg VERIFY_BIN_OK
    set /a PASS+=1
  ) else (
    call :msg VERIFY_BIN_FAIL
    call :msg VERIFY_BIN_ACTUAL
    echo                 !ACTUAL!
    call :msg VERIFY_BIN_EXPECTED
    set /a FAIL+=1
  )
) else (
  call :msg VERIFY_BIN_MISS
  set /a FAIL+=1
)

REM ---- 4. 检查 .env 配置 ----
call :msg VERIFY_ENV
if not exist "%~dp0.env" (
  call :msg VERIFY_ENV_MISS
  set /a FAIL+=1
) else (
  for /f "usebackq tokens=1,2 delims==" %%a in ("%~dp0.env") do (
    set "ENV_%%a=%%b"
  )
  if /i "!ENV_ANTHROPIC_BASE_URL!"=="" (
    call :msg VERIFY_ENV_NO_URL
    set /a FAIL+=1
  ) else (
    call :msg VERIFY_ENV_URL_OK
    set /a PASS+=1
  )
  if /i "!ENV_ANTHROPIC_API_KEY!"=="" (
    call :msg VERIFY_ENV_NO_KEY
    set /a FAIL+=1
  ) else (
    call :msg VERIFY_ENV_KEY_OK
    set /a PASS+=1
  )
  if "!ENV_DISABLE_AUTOUPDATER!"=="1" if "!ENV_CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC!"=="1" (
    call :msg VERIFY_ENV_ISOLATE_OK
    set /a PASS+=1
  ) else (
    call :msg VERIFY_ENV_ISOLATE_WARN
  )
)

REM ---- 5. 检查外网隔离 (最关键) ----
call :msg VERIFY_NET
curl -s -o nul -w "" --max-time 3 "https://downloads.claude.ai/" 2>nul
if %ERRORLEVEL%==0 (
  call :msg VERIFY_NET_FAIL
  set /a FAIL+=1
) else (
  call :msg VERIFY_NET_PASS_OK
  set /a PASS+=1
)

echo.
call :msg DEPLOY_BORDER2
echo   PASS=!PASS!  FAIL=!FAIL!
call :msg DEPLOY_BORDER2

if !FAIL! gtr 0 (
  call :msg VERIFY_SUMMARY_FAIL
  call :msg VERIFY_SUMMARY_FAIL
  echo         !FAIL!
  call :msg VERIFY_FAIL_SUFFIX
  exit /b 1
)
call :msg VERIFY_SUMMARY_PASS
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
