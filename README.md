# Claude Code 2.1.162 - 内网气隙部署包

> **目标**: Windows x64 + New API 网关 + GLM-5.1-AWQ-4bit 4-bit 量化模型
> **编制**: 2026-06-04 | **适用**: 完全气隙内网环境 (无任何外网通道)

---

## ⚠️ 关键澄清 (必读)

### 编码方案 (v3 升级)

本仓库所有 `.bat` / `.ps1` / `messages/zh.txt` 文件**统一采用 UTF-8 with BOM + CRLF 行尾**。

**为什么必须这样**:
- `chcp 65001` 把控制台**输出**切到 UTF-8 ✓
- 但 cmd.exe **解析 .bat 文件**时按**系统 OEM 代码页** (中文 Win=936/GBK) 读
- 文件没 BOM → cmd 不知道是 UTF-8 → 把 `中文` 当 GBK 解 → **乱码**
- 加 BOM (EF BB BF) → cmd 识别为 UTF-8 文件 → 正确解析 → **正常显示**

**深度方案**: 所有中文**外置**到 `messages/zh.txt` 字典,`.bat` 改为纯 ASCII + `call :msg LABEL` 子例程读字典。这样:
- `.bat` 文件 100% ASCII,任何 Windows locale 都跑得动
- 中文改字只需改 `zh.txt` 一处,不用动 `.bat`
- 永远不会乱码

**添加新中文消息**: 在 `messages/zh.txt` 加一行 `[YOUR_LABEL] 你的中文`,然后在 `.bat` 里 `call :msg YOUR_LABEL` 即可。

---

### Python 不需要

Claude Code 是 **Go 编写的单文件原生二进制**,自带 Node.js 运行时,**与 Python 无关**。
那台 Windows 机器**有没有 Python 都不影响**。

### 真气隙 vs 半离线

| 类型 | 含义 | 本仓库状态 |
|------|------|------------|
| 半离线 | 不下载安装包,但运行时会偷偷回拨外网 | ❌ |
| **真离线** | 运行时不发任何外网请求,只与内网 New API 通信 | ✅ |

Claude Code 二进制硬编码了 `downloads.claude.ai` / `api.anthropic.com` / `beacon.claude-ai.staging.ant.dev` 等外网地址,用于自动更新、错误上报、统计埋点。本仓库通过 6 个 `DISABLE_*` 环境变量**全部关闭**这些行为。

`run.bat` 中**强制硬编码**这些变量作为兜底,即使 .env 漏配也不会触网。

---

## 仓库结构 (代码+文档,不含大文件)

本仓库只包含脚本/配置/文档。**`.exe` 文件需手动下载**,放入对应位置:

```
claude-code-airgap/
├── README.md                      # 本文件
├── .env.template                  # 环境变量模板 (→ 复制为 .env)
├── .gitignore
├── claude_settings.json           # Claude Code 用户级 settings
├── manifest.json                  # 官方发布清单
├── setup.bat                      # 一键安装 (装依赖+校验+探测)
├── run.bat                        # 启动器 (含气隙隔离兜底)
├── 启动.ps1                       # PowerShell 入口 (Win10+PS5.1 编码安全)
├── install_settings.bat           # 推送 settings.json
├── install_deps.bat               # 单独装 Git + VC++
├── verify_airgap.bat              # 气隙验证 (5 步)
└── messages/
    └── zh.txt                     # 中文消息字典 (UTF-8 BOM)
├── uninstall.bat                  # 卸载脚本
├── 校验.bat                       # 离线 SHA256 校验
└── dependencies/                  # ⚠️ 需手动放入两个 .exe
    ├── Git-2.51.2-64-bit.exe     #   从 npmmirror 下载 (63MB)
    ├── vc_redist.x64.exe         #   从 Microsoft 下载 (24MB)
    └── SHA256SUMS.txt
```

**根目录的 `claude.exe` 同样需手动下载** (239MB,不在 git 仓库中)。

---

## 获取大文件 (联网环境)

### 1. claude.exe (239MB)

官方源: <https://downloads.claude.ai/claude-code-releases/2.1.162/win32-x64/claude.exe>
SHA256: `ac4e1319f6ac0c9e04336d0ae5845acc5dd317bf9e6f26ca47e63df06d91f8bc`

### 2. Git-2.51.2-64-bit.exe (63MB)

npmmirror 镜像 (国内高速):
<https://registry.npmmirror.com/-/binary/git-for-windows/v2.51.2.windows.1/Git-2.51.2-64-bit.exe>
SHA256: `ebd318e1d3ee0cc1ac8ead026f1edf8678dcb42c7d74d757b8e2fa8a1be0b25f`

### 3. vc_redist.x64.exe (24MB)

Microsoft 官方: <https://aka.ms/vs/17/release/vc_redist.x64.exe>
SHA256: `cc0ff0eb1dc3f5188ae6300faef32bf5beeba4bdd6e8e445a9184072096b713b`

---

## 部署步骤 (在内网 Windows 机器上执行)

### 前置: 在 New API 控制台准备

1. 登录 New API 后台 (`http://<newapi-host>:<port>`)
2. **渠道管理** → 新建 GLM-5.1 渠道:
   - 类型: 选 `OpenAI` 或自建 `自定义` 指向本地 GLM-5.1 服务
   - 模型名: `GLM-5.1-AWQ-4bit` (必须与此完全一致)
3. **令牌管理** → 新建 API Key,绑定上面的渠道
4. **确认 `/v1/messages` 路由已开启** (New API 默认开启 Anthropic 端点)
5. 测试联通 (在能访问 New API 的机器上):
   ```bash
   curl -X POST http://<newapi-host>:<port>/v1/messages \
     -H "x-api-key: <your-key>" \
     -H "anthropic-version: 2023-06-01" \
     -H "Content-Type: application/json" \
     -d '{"model":"GLM-5.1-AWQ-4bit","max_tokens":32,"messages":[{"role":"user","content":"hi"}]}'
   ```
   返回非 5xx 即为就绪。

> **为什么必须用 `ANTHROPIC_API_KEY`**：Claude Code 用 `ANTHROPIC_API_KEY` 才会发 `x-api-key` 头（New API 期望）；`ANTHROPIC_AUTH_TOKEN` 发的是 `Authorization: Bearer ...` 头，New API 的 Anthropic 兼容端点不认，会 401。

### 1. 拷贝仓库 + 手动放入 3 个 .exe

```cmd
git clone https://github.com/kogamishinyajerry-ops/claude-code-airgap.git
cd claude-code-airgap

REM 把下载的三个 exe 放入正确位置:
copy \path\to\claude.exe .
copy \path\to\Git-2.51.2-64-bit.exe dependencies\
copy \path\to\vc_redist.x64.exe dependencies\
```

**路径不能有中文或空格**,推荐放 `D:\claude-code-airgap\`

### 2. 准备 .env

```cmd
copy .env.template .env
notepad .env
```

填入实际值 (`.env.template` 里的 6 个 `DISABLE_*=1` 已默认开启,无需改):

```ini
ANTHROPIC_BASE_URL=http://10.x.x.x:3000/v1
ANTHROPIC_API_KEY=sk-xxxxxxxxxxxxxx
ANTHROPIC_MODEL=GLM-5.1-AWQ-4bit
```

### 3. 安装依赖 (首次部署)

`setup.bat` 会自动检测 Git 是否已装,未装则调用 `install_deps.bat` 静默安装。
如需手动提前安装:
```cmd
install_deps.bat
```

### 4. 一键部署

```cmd
setup.bat
```

这会:
- 自动检测/安装 Git + VC++ 依赖
- 校验 `claude.exe` 存在 + SHA256
- 加载 `.env` 变量
- 探测 New API 可达性 (内网)
- **验证外网已隔离** (尝试访问 downloads.claude.ai,应失败)
- (可选) `claude install` 注册 shell 集成;在气隙环境可能失败,**不影响使用**

### 5. 推送 settings.json

```cmd
install_settings.bat
```

把 `claude_settings.json` 拷到 `%USERPROFILE%\.claude\settings.json`,启用:
- 默认模型 `GLM-5.1-AWQ-4bit`
- 权限策略 `acceptEdits` (允许自动编辑文件,省心)

### 6. 启动

**方式 A: 命令行解释器 (默认)**
```cmd
run.bat
```

**方式 B: PowerShell (推荐,Win10 内网环境首选)**

`启动.ps1` 显式切到 UTF-8 代码页 + 设置控制台编码,**彻底解决 PowerShell 中文乱码**。
```powershell
Set-ExecutionPolicy -Scope Process Bypass; .\启动.ps1
# 或从 cmd / 资源管理器命令行:
powershell -ExecutionPolicy Bypass -File ".\启动.ps1"
```

传参同样支持:
```powershell
powershell -ExecutionPolicy Bypass -File ".\启动.ps1" --help
powershell -ExecutionPolicy Bypass -File ".\启动.ps1" "重构 utils.py"
```

**为什么用 `启动.ps1` 而非直接 `.\run.bat`**:
- PowerShell 默认是 GBK 控制台,`run.bat` 里的中文 banner 会在 PowerShell 终端乱码
- `启动.ps1` 顶部先 `chcp 65001` + 设 `[Console]::OutputEncoding = UTF8`,再调命令行解释器跑 run.bat
- 健康检查 (claude.exe / .env / run.bat 存在性) 在 PS 阶段就拦下,不会黑屏一闪

> **关于执行策略**:PowerShell 默认 Restricted 不允许跑 .ps1。用 `-ExecutionPolicy Bypass` 是单次放行,不修改全局策略,符合最小权限原则。

### 7. 验证气隙隔离 (推荐跑一遍)

```cmd
verify_airgap.bat
```

该脚本会检查:
- Git/VC++ 是否已装
- `claude.exe` SHA256 是否正确
- `.env` 配置是否完整
- **外网是否真的不可达** (HEAD 请求 downloads.claude.ai 应失败)

---

## 工作原理

```
[Claude Code (claude.exe)]
       │  Anthropic 协议
       │  POST /v1/messages
       ▼
[New API 网关]
       │  内部转换为 OpenAI 协议
       │  POST /v1/chat/completions
       ▼
[GLM-5.1-AWQ-4bit (vLLM / TGI / llama.cpp)]
```

环境变量决定一切:
| 变量 | 作用 |
|------|------|
| `ANTHROPIC_BASE_URL` | Claude Code 要打的地址,指向 New API 的 Anthropic 端点 |
| `ANTHROPIC_API_KEY` | New API 的 API Key (Claude Code 发 `x-api-key` 头) |
| `ANTHROPIC_MODEL` | 透传给上游的模型名,必须与 New API 渠道名一致 |
| `DISABLE_AUTOUPDATER` | 关闭 downloads.claude.ai 更新检查 (气隙必需) |
| `DISABLE_FEEDBACK_COMMAND` | 关闭 `/feedback` 命令回传 (气隙必需) |
| `DISABLE_ERROR_REPORTING` | 关闭错误上报 (气隙必需) |
| `DISABLE_TELEMETRY` | 关闭遥测统计 (气隙必需) |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | 一键合集 = 上面 4 个旧开关,双保险 (气隙必需) |
| `DO_NOT_TRACK` | 通用"请勿追踪"信号 (气隙必需) |

> 注意：旧名 `DISABLE_NONESSENTIAL_TRAFFIC`（不带前缀）在官方文档中不存在，会被忽略。同理 `DISABLE_INSTALLATION_CHECKS` 和 `DISABLE_GROWTHBOOK` 也不在官方支持列表，已从本仓库删除。

---

## 故障排查

| 现象 | 原因 | 解决 |
|------|------|------|
| `claude.exe install` 失败 | 杀毒软件拦截 / 外网隔离 | 加入白名单,`run.bat` 不依赖 install |
| `401 Unauthorized` | API Key 错、用错环境变量（`ANTHROPIC_AUTH_TOKEN` 发的是 Bearer 头不是 x-api-key）、或绑定的渠道没有该模型 | 必须用 `ANTHROPIC_API_KEY`；在 New API 控制台核对 Key 和渠道 |
| `404 model not found` | `ANTHROPIC_MODEL` 与 New API 渠道名不一致 | 严格大小写匹配 |
| `connection refused` | New API 不通 | `telnet <newapi-host> <port>` 检查网络 |
| `VCRUNTIME140.dll` 缺失 | 缺 VC++ 运行时 | 跑 `install_deps.bat` |
| PowerShell 不认 `claude` 命令 | `install` 没执行或 PATH 没刷新 | 重开终端 |
| PowerShell 跑 `run.bat` 中文乱码 | 控制台默认 GBK 编码 | 改用 `启动.ps1` (本仓库自带) |
| PowerShell 拦 `启动.ps1` 不让跑 | 默认 Restricted 执行策略 | 用 `Set-ExecutionPolicy -Scope Process Bypass` 或 `powershell -ExecutionPolicy Bypass -File ".\启动.ps1"` |

---

## 升级方法

升级只需替换 `claude.exe` 一个文件:
1. 联网机器下载新版本 (替换 URL 中的版本号):
   ```
   https://downloads.claude.ai/claude-code-releases/<NEW_VERSION>/win32-x64/claude.exe
   ```
2. 同时更新 `manifest.json`:
   ```
   https://downloads.claude.ai/claude-code-releases/<NEW_VERSION>/manifest.json
   ```
3. 拷贝到内网覆盖旧文件
4. 重启所有 Claude Code 进程

---

## License

MIT
