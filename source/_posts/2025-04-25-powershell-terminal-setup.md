---
layout: post
date: 2025-04-25 08:00:00
updated: 2025-04-25 08:00:00
title: "PowerShell 技能连载 - Windows Terminal 与 PowerShell 环境配置"
description: PowerTip of the Day - Windows Terminal and PowerShell Environment Setup
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- terminal
- windows-terminal
- oh-my-posh
- productivity
---

_适用于 Windows 10/11，PowerShell 7.0 及以上版本_

<!-- more -->

## 为什么终端环境如此重要

作为 PowerShell 用户，终端是每天打交道最多的工具。一个配置得当的终端环境不仅能让你心情愉悦，更能显著提升工作效率。试想一下：当你打开终端，迎接你的是清晰的配色、醒目的 Git 状态提示、智能的命令补全，和一系列顺手可用的自定义函数——是不是比面对默认的蓝底白字更有动力？

传统的 Windows PowerShell 5.1 控制台（conhost）功能有限，不支持多标签、缺乏自定义能力。而 Windows Terminal 的出现彻底改变了这一局面：它是开源的、高度可定制的、支持 GPU 加速渲染的现代终端应用。配合 PowerShell 7 和 Oh My Posh，我们可以打造一个不输 macOS/Linux 的终端体验。

本文将从 Windows Terminal 配置、PowerShell 7 Profile 定制、Oh My Posh 美化、PSReadLine 增强以及常用别名函数五个方面，带你一步步搭建理想的终端环境。

## Windows Terminal 基础配置

Windows Terminal 的配置存储在一个 JSON 文件中，通过 `Ctrl+Shift+,` 可以快速打开。以下是一个经过优化的配置片段，涵盖默认配置文件、启动目录、字体和配色方案。

```powershell
# 查看 Windows Terminal settings.json 的路径
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Write-Host "Windows Terminal 配置文件路径: $settingsPath"

# 如果文件存在，读取当前默认配置
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $defaultProfile = $settings.profiles.list | Where-Object { $_.guid -eq $settings.defaultProfile }
    Write-Host "当前默认配置文件: $($defaultProfile.name)"
} else {
    Write-Host "未找到 Windows Terminal 配置文件，请确认已安装 Windows Terminal"
}
```

执行结果示例：

```
Windows Terminal 配置文件路径: C:\Users\dev\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
当前默认配置文件: PowerShell 7
```

在 `settings.json` 中，以下几项配置值得优先调整：

- `defaultProfile`：设置为 PowerShell 7 的 GUID，确保默认打开的是 PS7
- `startingDirectory`：设定为你常用的工作目录
- `font.face`：推荐使用 Nerd Font，以支持 Oh My Posh 的图标显示
- `colorScheme`：选择一个护眼且对比度适中的配色方案

## PowerShell 7 Profile 定制

PowerShell 的 Profile 文件类似于 bash 的 `.bashrc`，每次启动 PowerShell 时自动执行。PS7 的 Profile 路径与 PS5.1 不同，互不干扰。

```powershell
# 查看 PowerShell 7 的所有 Profile 路径
$PROFILE | Format-List -Force
```

执行结果示例：

```
AllUsersAllHosts       : C:\Program Files\PowerShell\7\profile.ps1
AllUsersCurrentHost    : C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1
CurrentUserAllHosts    : C:\Users\dev\Documents\PowerShell\profile.ps1
CurrentUserCurrentHost : C:\Users\dev\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

最常用的是 `CurrentUserCurrentHost`，即当前用户、当前宿主的 Profile。我们来创建一个基础 Profile，包含环境变量设置和模块导入：

```powershell
# 确保 Profile 目录存在
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "已创建 Profile 目录: $profileDir"
}

# 创建初始 Profile 文件
$profileContent = @'
# === 环境变量 ===
$env:EDITOR = "code"
$env:PYTHONIOENCODING = "utf-8"

# === 编码设置 ===
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# === 常用模块自动导入 ===
$modulesToImport = @(
    "PSReadLine",
    "Terminal-Icons"
)

foreach ($mod in $modulesToImport) {
    if (Get-Module -ListAvailable -Name $mod) {
        Import-Module $mod -ErrorAction SilentlyContinue
    }
}

Write-Host "Profile 加载完成 - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray
'@

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
Write-Host "Profile 文件已写入: $PROFILE"
```

执行结果示例：

```
Profile 文件已写入: C:\Users\dev\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

这段 Profile 做了几件关键的事：统一了编码为 UTF-8（避免中文乱码）、设置了默认编辑器、自动导入常用模块。编码问题是 Windows 下开发最常遇到的坑之一，在 Profile 中统一处理可以省去大量排查时间。

## Oh My Posh 终端美化

Oh My Posh 是 Windows 上最流行的终端提示符美化工具，它能为你的终端添加 Git 状态、语言版本、执行时间等信息。配合 Nerd Font，还可以显示丰富的图标。

```powershell
# 安装 Oh My Posh（推荐通过 winget）
winget install JanDeDobbeleer.OhMyPosh -s winget

# 安装推荐的 Nerd Font
oh-my-posh font install FiraCode

# 查看可用的主题列表
oh-my-posh get shell
Write-Host "可用主题数量: $((oh-my-posh get themes).Count)"
```

执行结果示例：

```
已成功安装 Oh My Posh
正在安装 FiraCode Nerd Font...
已完成字体安装
可用主题数量: 87
```

在 Profile 中初始化 Oh My Posh。注意不要在 here-string 中使用三反引号，我们用变量拼接的方式来设置主题路径：

```powershell
# 将 Oh My Posh 初始化代码添加到 Profile
$ompInit = @'
# === Oh My Posh 初始化 ===
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = Join-Path $env:POSH_THEMES_PATH "jandebuhr.omp.json"
    if (-not (Test-Path $ompTheme)) {
        $ompTheme = "jandedeurbel"
    }
    oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
}
'@

# 追加到 Profile 末尾
Add-Content -Path $PROFILE -Value "`n$ompInit" -Encoding UTF8
Write-Host "Oh My Posh 初始化代码已添加到 Profile"
```

执行结果示例：

```
Oh My Posh 初始化代码已添加到 Profile
```

Oh My Posh 的主题文件是 JSON 格式，你也可以自定义主题。推荐先用内置主题找到喜欢的风格，再在此基础上微调颜色和段落的显示顺序。一个好主题应该在美观和信息密度之间取得平衡——信息太少不实用，太多则显得杂乱。

## 常用别名与自定义函数

Profile 中最实用的部分之一就是定义别名和函数，把日常高频操作压缩成简短的命令。以下是笔者常用的配置：

```powershell
# 定义常用别名和函数
$aliasAndFuncs = @'
# === 常用别名 ===
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command
Set-Alias -Name touch -Value New-Item
Set-Alias -Name cat -Value Get-Content

# === 自定义函数 ===

# 快速进入项目目录
function projects {
    Set-Location "D:\Projects"
}

# 快速查看端口占用
function port {
    param([int]$PortNumber)
    Get-NetTCPConnection -LocalPort $PortNumber -ErrorAction SilentlyContinue |
        Select-Object LocalPort, OwningProcess, State |
        Format-Table -AutoSize
}

# 快速查看系统信息
function sysinfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $mem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        OS           = $os.Caption
        CPU          = $cpu.Name
        FreeMem_GB   = $mem
        Uptime       = (Get-Date) - $os.LastBootUpTime
    } | Format-List
}

# Git 快捷操作
function gs { git status }
function gl { git log --oneline -15 }
function gp { git push }
function gd { git diff $args }

# Docker 快捷操作
function dps { docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" }
function dex {
    param([string]$ContainerName)
    docker exec -it $ContainerName /bin/sh
}
'@

Add-Content -Path $PROFILE -Value "`n$aliasAndFuncs" -Encoding UTF8
Write-Host "别名和函数已添加到 Profile"
```

执行结果示例：

```
别名和函数已添加到 Profile
```

这些函数的设计原则是"短小精悍"：每个函数只做一件事，名字尽量简短但能望文生义。比如 `port 8080` 比输入完整的 `Get-NetTCPConnection -LocalPort 8080` 简洁得多，`gs` 则是 `git status` 的经典缩写。你可以根据自己的工作流继续扩展这个列表。

## PSReadLine 增强补全

PSReadLine 是 PowerShell 的命令行编辑模块，PS7 已内置 2.x 版本。合理配置后，它能提供类似 fish shell 的自动补全体验——输入时实时预测、历史命令搜索、语法高亮一应俱全。

```powershell
# 配置 PSReadLine
$psreadlineConfig = @'
# === PSReadLine 配置 ===
if ($host.Name -eq 'ConsoleHost') {
    # 预测文本来源：历史记录 + 插件
    Set-PSReadLineOption -PredictiveSource HistoryAndPlugin
    # 预测文本显示方式：列表视图（类似 fish）
    Set-PSReadLineOption -PredictiveStyle ListView
    # 历史记录去重
    Set-PSReadLineOption -HistoryNoDuplicates
    # 保存历史记录条数
    Set-PSReadLineOption -MaximumHistoryCount 10000
    # 历史记录保存路径
    Set-PSReadLineOption -HistorySavePath (Join-Path $env:USERPROFILE ".ps_history")
    # 编辑模式设为 Emacs（更符合开发习惯）
    Set-PSReadLineOption -EditMode Emacs
    # 颜色主题
    Set-PSReadLineOption -Colors @{
        Command            = 'Yellow'
        Parameter          = 'Green'
        String             = 'Cyan'
        Comment            = 'DarkGray'
        Operator           = 'Magenta'
        Prediction         = 'DarkGray'
        InlinePrediction  = 'DarkGray'
    }

    # Ctrl+d 删除字符（类似 bash）
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    # Ctrl+w 删除前一个单词
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord
    # 上下箭头在预测列表中导航
    Set-PSReadLineKeyHandler -Chord UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    # Tab 补全显示菜单
    Set-PSReadLineKeyHandler -Chord Tab     -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord Shift+Tab -Function Complete
}
'@

Add-Content -Path $PROFILE -Value "`n$psreadlineConfig" -Encoding UTF8
Write-Host "PSReadLine 配置已添加到 Profile"
```

执行结果示例：

```
PSReadLine 配置已添加到 Profile
```

PSReadLine 的预测补全功能是提升效率的关键。当你开始输入命令时，它会根据历史记录实时显示匹配建议，按右箭头即可接受。`ListView` 模式下还会显示一个下拉列表供你选择，配合 `HistoryAndPlugin` 来源，补全的准确度非常高。

## 完整 Profile 模板

经过以上各部分的配置，下面给出一个完整的 Profile 模板，方便你一次性部署。建议按需修改目录路径和主题名称。

```powershell
# 生成完整 Profile 模板
$templateContent = @'
# ============================================
# PowerShell 7 Profile - 完整模板
# 生成日期: 2025-04-25
# ============================================

# === 编码设置 ===
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# === 环境变量 ===
$env:EDITOR = "code"

# === Oh My Posh ===
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = Join-Path $env:POSH_THEMES_PATH "jandebuhr.omp.json"
    if (-not (Test-Path $ompTheme)) { $ompTheme = "jandedeurbel" }
    oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
}

# === 模块导入 ===
$autoModules = @("Terminal-Icons")
foreach ($m in $autoModules) {
    if (Get-Module -ListAvailable -Name $m) {
        Import-Module $m -ErrorAction SilentlyContinue
    }
}

# === PSReadLine ===
if ($host.Name -eq 'ConsoleHost') {
    Set-PSReadLineOption -PredictiveSource HistoryAndPlugin
    Set-PSReadLineOption -PredictiveStyle ListView
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -MaximumHistoryCount 10000
    Set-PSReadLineOption -HistorySavePath (Join-Path $env:USERPROFILE ".ps_history")
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -Colors @{
        Command           = 'Yellow'
        Parameter         = 'Green'
        String            = 'Cyan'
        Comment           = 'DarkGray'
        Prediction        = 'DarkGray'
        InlinePrediction  = 'DarkGray'
    }
    Set-PSReadLineKeyHandler -Chord UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Tab       -Function MenuComplete
}

# === 别名 ===
Set-Alias ll Get-ChildItem
Set-Alias which Get-Command
Set-Alias touch New-Item

# === 自定义函数 ===
function projects { Set-Location "D:\Projects" }
function port([int]$p) { Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue | Format-Table -AutoSize }
function sysinfo {
    $os = Get-CimInstance Win32_OperatingSystem
    [PSCustomObject]@{
        Computer  = $env:COMPUTERNAME
        OS        = $os.Caption
        FreeMemGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        Uptime    = (Get-Date) - $os.LastBootUpTime
    } | Format-List
}

# === Git 快捷命令 ===
function gs { git status }
function gl { git log --oneline -15 }
function gp { git push }

Write-Host "Profile loaded - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray
'@

# 写入 Profile
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
Set-Content -Path $PROFILE -Value $templateContent -Encoding UTF8
Write-Host "完整 Profile 模板已写入: $PROFILE"
```

执行结果示例：

```
完整 Profile 模板已写入: C:\Users\dev\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

部署完成后，重新打开 Windows Terminal 或执行 `. $PROFILE` 即可生效。首次加载时 Oh My Posh 会编译主题缓存，之后启动速度很快。如果遇到图标显示为方块，说明 Nerd Font 未正确安装或 Windows Terminal 未配置使用该字体。

## 注意事项

1. **Profile 加载顺序**：Oh My Posh 初始化应放在 PSReadLine 配置之前，否则预测补全的颜色设置可能被覆盖。
2. **Nerd Font 必须在 Windows Terminal 中指定**：仅安装字体不够，还需要在 `settings.json` 的 profile 中设置 `"font": { "face": "FiraCode Nerd Font" }`。
3. **Profile 修改后别忘重载**：修改 Profile 后，在当前会话中执行 `. $PROFILE` 重新加载，避免关闭重开。
4. **编码一致性**：确保 `settings.json`、Profile 文件和系统区域设置都使用 UTF-8，否则中文可能显示为乱码。
5. **备份你的配置**：建议将 Profile 文件和 `settings.json` 纳入 Git 管理，换机器时一键恢复。
6. **PSReadLine 插件模式**：`PredictiveSource HistoryAndPlugin` 需要安装补全模块（如 `CompletionPredictor`），如果未安装则回退到纯历史记录模式，不会报错。
