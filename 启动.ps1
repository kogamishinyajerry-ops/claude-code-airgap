# 启动.ps1 - Claude Code 气隙部署 PowerShell 入口
# 适用: Windows 10 + PowerShell 5.1 (默认配置,无任何依赖)
#
# 用法 1 (在 PowerShell 中):
#     Set-ExecutionPolicy -Scope Process Bypass; .\启动.ps1
# 用法 2 (命令行):
#     powershell -ExecutionPolicy Bypass -File ".\启动.ps1"
# 用法 3 (传参):
#     powershell -ExecutionPolicy Bypass -File ".\启动.ps1" --help
#     powershell -ExecutionPolicy Bypass -File ".\启动.ps1" "重构 utils.py"
#
# 设计原则:
#   1. 第一件事切 UTF-8 (避免中文乱码)
#   2. 第二件事切到脚本所在目录 (不依赖 cd)
#   3. 第三件事调用命令行解释器解释 run.bat (命令行解释器对 .bat 路径处理最稳)
#   4. 退出码透传给调用方

#Requires -Version 5.1

# ---- 1. 强制 UTF-8 (必须在写中文之前) ----
try { chcp 65001 | Out-Null } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { $OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ---- 2. 切到脚本所在目录 (用 $PSScriptRoot,不依赖 cd) ----
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = (Get-Location).Path
}
Set-Location -LiteralPath $ScriptDir

# ---- 3. 健康检查 (给清晰的错误信息,而不是黑屏一闪) ----
# 非交互模式防护: try/catch 包裹 Read-Host,异常则不挂
# (IsInputRedirected 在某些 IDE/host 下不可靠, catch 才是最稳的二层防御)
function Wait-IfInteractive {
    try {
        Read-Host '按 Enter 退出' | Out-Null
    } catch {
        # 非交互模式 (stdin=pipe / IDE host) 静默忽略,不影响 exit code
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $ScriptDir 'claude.exe'))) {
    Write-Host '[ERROR] claude.exe 不存在: ' -NoNewline -ForegroundColor Red
    Write-Host (Join-Path $ScriptDir 'claude.exe')
    Write-Host '        请先把 claude.exe (239MB) 放到本目录'
    Write-Host '        下载地址见 README.md 第 3 节 获取大文件'
    Wait-IfInteractive
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $ScriptDir '.env'))) {
    Write-Host '[ERROR] .env 不存在' -ForegroundColor Red
    Write-Host '        Copy-Item .env.template .env; notepad .env'
    Wait-IfInteractive
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $ScriptDir 'run.bat'))) {
    Write-Host '[ERROR] run.bat 不存在,启动中止' -ForegroundColor Red
    Wait-IfInteractive
    exit 1
}

# ---- 4. 转发参数给 run.bat (用 Start-Process 数组形式,避免转义问题) ----
$cmdArgs = @('/d', '/c', 'run.bat') + $args
Write-Host ''
Write-Host '[INFO] 正在启动 Claude Code (命令行解释器模式) ...'
Write-Host '[INFO] 工作目录: ' -NoNewline
Write-Host $ScriptDir
Write-Host ''

# 显式调用命令行解释器解释 .bat, -Wait 等 run.bat 退出, -PassThru 拿退出码
$proc = Start-Process -FilePath "$env:SystemRoot\System32\cmd.exe" `
    -ArgumentList $cmdArgs `
    -WorkingDirectory $ScriptDir `
    -NoNewWindow -Wait -PassThru

exit $proc.ExitCode
