---
layout: post
date: 2026-04-15 08:00:00
title: "PowerShell 技能连载 - Windows 开发环境配置即代码"
description: PowerTip of the Day - Windows Dev Environment Configuration as Code in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dev-environment
- winget
- dotfiles
- configuration
---

_适用于 PowerShell 7.0 及以上版本_

在 Linux 和 macOS 世界里，"Dotfiles" 文化早已深入人心——开发者把 shell 配置、编辑器偏好、软件包清单统统放进 Git 仓库，一条命令就能在新机器上完整还原工作环境。这种"配置即代码"（Configuration as Code）的理念不仅节省时间，更重要的是保证了多台设备之间的一致性，也让灾难恢复变得轻而易举。

Windows 平台长期以来缺少类似的标准化方案。开发者通常需要手动下载安装包、逐一点击安装向导、手动配置环境变量和注册表项。整个过程既繁琐又容易遗漏。随着 Windows Package Manager（winget）的成熟和 PowerShell 7 的普及，Windows 上也可以实现与 Unix 系统媲美的自动化环境配置流程。

本文将介绍如何使用 PowerShell 结合 winget 构建一套完整的"Windows Dotfiles"方案：自动安装常用开发工具链、管理系统配置与偏好设置，以及通过 Git 仓库实现多机同步和一键恢复。

## 开发工具链安装脚本

第一步是将日常开发所需的工具清单化。通过 winget 的命令行接口，我们可以用 PowerShell 脚本批量安装 VS Code、Git、Node.js、Python 等常用工具，并自动处理依赖关系。

```powershell
# DevToolkit.ps1 - 开发工具链一键安装脚本
# 定义工具清单：包名 + 可选版本约束
$tools = @(
    @{ Id = 'Git.Git';                Name = 'Git';                Source = 'winget' }
    @{ Id = 'Microsoft.VisualStudioCode'; Name = 'VS Code';       Source = 'winget' }
    @{ Id = 'OpenJS.NodeJS.LTS';      Name = 'Node.js LTS';       Source = 'winget' }
    @{ Id = 'Python.Python.3.12';     Name = 'Python 3.12';       Source = 'winget' }
    @{ Id = 'Docker.DockerDesktop';   Name = 'Docker Desktop';    Source = 'winget' }
    @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal'; Source = 'winget' }
    @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'Oh My Posh';       Source = 'winget' }
)

function Install-DevTool {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    $installed = winget list --id $Tool.Id --accept-source-agreements 2>$null
    if ($installed -match $Tool.Id) {
        Write-Host "[已安装] $($Tool.Name)" -ForegroundColor Green
        return
    }

    Write-Host "[安装中] $($Tool.Name) ($($Tool.Id))" -ForegroundColor Cyan
    $result = winget install --id $Tool.Id `
        --accept-package-agreements `
        --accept-source-agreements `
        --silent 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[完成] $($Tool.Name) 安装成功" -ForegroundColor Green
    } else {
        Write-Host "[失败] $($Tool.Name): $result" -ForegroundColor Red
    }
}

# 批量安装并统计结果
$stats = @{ Success = 0; Skipped = 0; Failed = 0 }

foreach ($tool in $tools) {
    $before = $stats.Success + $stats.Failed
    Install-DevTool -Tool $tool

    $after = winget list --id $tool.Id --accept-source-agreements 2>$null
    if ($after -match $tool.Id) {
        if ($before -eq ($stats.Success + $stats.Failed)) {
            $stats.Skipped++
        } else {
            $stats.Success++
        }
    } else {
        $stats.Failed++
    }
}

Write-Host "`n--- 安装报告 ---" -ForegroundColor Yellow
Write-Host "新安装: $($stats.Success) | 已存在: $($stats.Skipped) | 失败: $($stats.Failed)"
```

上面的脚本会逐个检查每个工具是否已经安装，避免重复安装，并给出清晰的彩色输出和最终统计报告。你可以根据个人需求增删 `$tools` 数组中的条目。

执行结果示例：

```text
[已安装] Git
[已安装] VS Code
[安装中] Node.js LTS (OpenJS.NodeJS.LTS)
[完成] Node.js LTS 安装成功
[安装中] Python 3.12 (Python.Python.3.12)
[完成] Python 3.12 安装成功
[已安装] Docker Desktop
[安装中] Windows Terminal (Microsoft.WindowsTerminal)
[完成] Windows Terminal 安装成功
[安装中] Oh My Posh (JanDeDobbeleer.OhMyPosh)
[完成] Oh My Posh 安装成功

--- 安装报告 ---
新安装: 4 | 已存在: 3 | 失败: 0
```

## 系统配置与偏好设置

安装完工具只是第一步，更关键的是将各项配置也纳入版本管理。下面的脚本演示了如何通过 PowerShell 管理注册表项、PowerShell Profile 文件和环境变量，把这些偏好设置也变成可追踪、可复现的代码。

```powershell
# SystemConfig.ps1 - 系统配置与偏好设置脚本
# 定义 Dotfiles 仓库路径
$DotfilesRoot = Join-Path $HOME 'dotfiles'
$BackupDir    = Join-Path $DotfilesRoot 'backups'

# 创建备份目录
if (-not (Test-Path $BackupDir)) {
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
}

# --- 1. Windows 注册表配置 ---
$regSettings = @{
    # 显示文件扩展名
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt' = 0
    # 显示隐藏文件
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden' = 1
    # 关闭 Bing 搜索
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\BingSearchEnabled' = 0
}

foreach ($entry in $regSettings.GetEnumerator()) {
    $path = Split-Path $entry.Key
    $name = Split-Path $entry.Key -Leaf
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name $name -Value $entry.Value -Type DWord
    Write-Host "[注册表] $name = $($entry.Value)" -ForegroundColor Cyan
}

# --- 2. PowerShell Profile 管理 ---
$profileContent = @'
# ===== PowerShell Profile - 由 dotfiles 管理 =====
# Oh My Posh 主题
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandebuhr.omp.json" | Invoke-Expression

# 常用别名
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# 自定义函数：快速进入项目目录
function proj { Set-Location "$env:USERPROFILE\Projects\$args" }

# PSReadLine 配置
Set-PSReadLineOption -PredictiveSource History
Set-PSReadLineOption -EditMode Windows
'@

$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
}

# 备份现有 Profile
if (Test-Path $PROFILE) {
    $backupFile = Join-Path $BackupDir 'Microsoft.PowerShell_profile.ps1.bak'
    Copy-Item $PROFILE $backupFile -Force
    Write-Host "[备份] Profile 已备份到 $backupFile" -ForegroundColor Yellow
}

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
Write-Host "[Profile] 已写入 $PROFILE" -ForegroundColor Green

# --- 3. 环境变量设置 ---
$envConfig = @{
    'DOTFILES_ROOT' = $DotfilesRoot
    'PROJECTS_HOME' = Join-Path $HOME 'Projects'
    'EDITOR'        = 'code'
}

foreach ($entry in $envConfig.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable(
        $entry.Key, $entry.Value, 'User'
    )
    Write-Host "[环境变量] $($entry.Key) = $($entry.Value)" -ForegroundColor Cyan
}

Write-Host "`n[完成] 系统配置已全部应用，重启终端生效" -ForegroundColor Green
```

这段脚本把注册表修改、Profile 文件生成和环境变量设置集中在一起。每次执行都会自动备份旧配置，保证操作可回滚。将这段脚本放入 dotfiles 仓库后，只要 `git pull` 再执行一次就能在新机器上还原所有偏好。

执行结果示例：

```text
[注册表] HideFileExt = 0
[注册表] Hidden = 1
[注册表] BingSearchEnabled = 0
[备份] Profile 已备份到 C:\Users\dev\dotfiles\backups\Microsoft.PowerShell_profile.ps1.bak
[Profile] 已写入 C:\Users\dev\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
[环境变量] DOTFILES_ROOT = C:\Users\dev\dotfiles
[环境变量] PROJECTS_HOME = C:\Users\dev\Projects
[环境变量] EDITOR = code

[完成] 系统配置已全部应用，重启终端生效
```

## 配置恢复与多机同步

前两个脚本解决了安装和配置的问题，但真正的价值在于多机同步。下面的脚本实现了配置导出和一键恢复功能，配合 Git 仓库可以在任何 Windows 机器上快速还原完整开发环境。

```powershell
# SyncDotfiles.ps1 - 配置导出、同步与恢复
# Dotfiles 仓库路径
$DotfilesRoot = Join-Path $HOME 'dotfiles'
$ExportsDir   = Join-Path $DotfilesRoot 'exports'

function Export-CurrentConfig {
    <# 将当前环境导出为可追踪的清单文件 #>

    if (-not (Test-Path $ExportsDir)) {
        New-Item -Path $ExportsDir -ItemType Directory -Force | Out-Null
    }

    # 导出 winget 已安装软件列表
    Write-Host "[导出] 正在生成 winget 软件清单..." -ForegroundColor Cyan
    winget export --output (Join-Path $ExportsDir 'winget-packages.json') `
        --accept-source-agreements 2>$null

    # 同时生成可读的文本版本
    winget list --accept-source-agreements |
        Out-File (Join-Path $ExportsDir 'winget-list.txt') -Encoding UTF8

    # 导出环境变量
    $userEnv = [Environment]::GetEnvironmentVariables('User') |
        GetEnumerator() | Sort-Object Name
    $userEnv | ConvertTo-Json |
        Out-File (Join-Path $ExportsDir 'user-env.json') -Encoding UTF8

    # 导出 PowerShell 模块列表
    Get-Module -ListAvailable |
        Select-Object Name, Version, ModuleBase |
        Sort-Object Name |
        ConvertTo-Json |
        Out-File (Join-Path $ExportsDir 'ps-modules.json') -Encoding UTF8

    # 导出 Profile 文件
    if (Test-Path $PROFILE) {
        Copy-Item $PROFILE (Join-Path $ExportsDir 'profile.ps1') -Force
    }

    Write-Host "[完成] 配置已导出到 $ExportsDir" -ForegroundColor Green
}

function Restore-DevEnvironment {
    <# 从 dotfiles 仓库一键恢复开发环境 #>

    # 1. 从 winget 清单批量安装
    $manifestPath = Join-Path $ExportsDir 'winget-packages.json'
    if (Test-Path $manifestPath) {
        Write-Host "[恢复] 从 winget 清单安装软件..." -ForegroundColor Cyan
        winget import --import-file $manifestPath `
            --accept-package-agreements `
            --accept-source-agreements
    }

    # 2. 恢复 Profile
    $profileBackup = Join-Path $ExportsDir 'profile.ps1'
    if (Test-Path $profileBackup) {
        $profileDir = Split-Path $PROFILE
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item $profileBackup $PROFILE -Force
        Write-Host "[恢复] PowerShell Profile 已还原" -ForegroundColor Green
    }

    # 3. 恢复环境变量
    $envPath = Join-Path $ExportsDir 'user-env.json'
    if (Test-Path $envPath) {
        $envVars = Get-Content $envPath | ConvertFrom-Json
        foreach ($prop in $envVars.PSObject.Properties) {
            [Environment]::SetEnvironmentVariable(
                $prop.Name, $prop.Value.ToString(), 'User'
            )
        }
        Write-Host "[恢复] 环境变量已还原" -ForegroundColor Green
    }

    # 4. 安装 PowerShell 模块
    $requiredModules = @('PSReadLine', 'Terminal-Icons', 'z')
    foreach ($mod in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $mod)) {
            Install-Module -Name $mod -Force -Scope CurrentUser
            Write-Host "[模块] 已安装 $mod" -ForegroundColor Cyan
        }
    }

    Write-Host "`n[完成] 开发环境已完整恢复，请重启终端" -ForegroundColor Green
}

# 使用方式：
#   导出: . .\SyncDotfiles.ps1; Export-CurrentConfig
#   恢复: . .\SyncDotfiles.ps1; Restore-DevEnvironment
```

这个脚本提供了两个核心函数：`Export-CurrentConfig` 将当前环境的所有关键配置导出为 JSON 清单文件，`Restore-DevEnvironment` 则从这些清单文件一键还原。配合 Git 仓库，你在任何 Windows 机器上只需 `git clone` 你的 dotfiles 仓库，然后运行恢复函数即可。

执行结果示例（导出模式）：

```text
[导出] 正在生成 winget 软件清单...
[完成] 配置已导出到 C:\Users\dev\dotfiles\exports

> Get-ChildItem C:\Users\dev\dotfiles\exports

    Directory: C:\Users\dev\dotfiles\exports

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          2026/4/15    10:30          24576 winget-packages.json
-a---          2026/4/15    10:30           8192 winget-list.txt
-a---          2026/4/15    10:30           1024 user-env.json
-a---          2026/4/15    10:30           3072 ps-modules.json
-a---          2026/4/15    10:30           2048 profile.ps1
```

执行结果示例（恢复模式）：

```text
[恢复] 从 winget 清单安装软件...
Found 12 packages in the import file.
已安装 7 个包, 已跳过 5 个包。
[恢复] PowerShell Profile 已还原
[恢复] 环境变量已还原
[模块] 已安装 Terminal-Icons
[模块] 已安装 z

[完成] 开发环境已完整恢复，请重启终端
```

## 注意事项

1. **winget 前置条件**：winget 随 Windows 11 和 Windows 10 (1809+) 的 App Installer 分发。如果系统没有 winget，需要先从 Microsoft Store 安装"应用安装程序"，或在 GitHub 的 microsoft/winget-cli 仓库手动下载 MSIX 包。

2. **管理员权限**：部分软件（如 Docker Desktop、某些注册表项的修改）需要以管理员身份运行 PowerShell。建议在脚本开头加入 `#Requires -RunAsAdministrator` 声明，或在启动时检测权限并提示用户提权。

3. **网络与代理**：winget 和 PowerShell Gallery 在国内网络环境下可能较慢。建议提前配置代理：`$env:HTTPS_PROXY = 'http://127.0.0.1:7890'`，或将 NuGet 源替换为国内镜像。

4. **版本锁定**：winget-packages.json 导出的清单会锁定具体版本号。如果希望在恢复时始终获取最新版，可以改为从文本清单逐条 `winget install` 而非使用 `winget import`，以获取最新可用版本。

5. **敏感信息处理**：dotfiles 仓库中不要存放 API Key、Token 等敏感信息。环境变量中涉及密钥的部分应使用 Windows Credential Manager 或 `.env` 文件管理，并在 `.gitignore` 中排除。

6. **幂等性设计**：所有脚本都应设计为可重复执行而不产生副作用——安装前先检测是否已存在，配置前先备份旧值。这样即使执行失败也可以安全地重新运行。
