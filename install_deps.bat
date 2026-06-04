@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /d "%~dp0"

call :msg DEPLOY_BORDER
call :msg DEPS_TITLE
call :msg DEPLOY_BORDER
echo.

REM 1.  VC++ Redist (, UI)
call :msg DEPS_VC_HEADER
if exist "dependencies\vc_redist.x64.exe" (
  call :msg DEPS_VC_RUN
  reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>nul
  if %ERRORLEVEL%==0 (
    call :msg DEPS_VC_OK
  ) else (
    "dependencies\vc_redist.x64.exe" /install /quiet /norestart
    set ERRORLEVEL=!ERRORLEVEL!
    if !ERRORLEVEL!==0 (
      call :msg DEPS_VC_OK
    ) else (
      call :msg DEPS_VC_WARN
      echo         !ERRORLEVEL!,
      call :msg DEPS_VC_MAY_MANUAL_HINT
    )
  )
) else (
  call :msg DEPS_VC_SKIP
)

REM 2.  Git (,Git Bash +  PATH)
call :msg DEPS_GIT_HEADER
if exist "dependencies\Git-2.51.2-64-bit.exe" (
  call :msg DEPS_GIT_RUN
  call :msg DEPS_GIT_NOTE
  call :msg DEPS_GIT_FLAG_NOTE
  "dependencies\Git-2.51.2-64-bit.exe" /SP- /VERYSILENT /NORESTART
  set ERRORLEVEL=!ERRORLEVEL!
  if !ERRORLEVEL! neq 0 (
    call :msg DEPS_GIT_WARN
    echo         !ERRORLEVEL!,
    call :msg DEPS_GIT_MANUAL_HINT
  )
) else (
  call :msg DEPS_GIT_SKIP
)

REM 3.  PATH  git
call :msg DEPS_VERIFY_HEADER
call :msg DEPS_VERIFY_RUN
where git >nul 2>nul
if %ERRORLEVEL%==0 (
  call :msg VERIFY_DEP_GIT_OK
) else (
  call :msg DEPS_VERIFY_WARN
)

echo.
call :msg DEPLOY_BORDER
call :msg DEPS_DONE
call :msg DEPS_DONE_NEXT
call :msg DEPLOY_BORDER
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
