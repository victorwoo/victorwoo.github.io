---
layout: post
date: 2026-03-19 08:00:00
updated: 2026-03-19 08:00:00
title: "PowerShell 技能连载 - 提示符与界面定制"
description: PowerTip of the Day - Prompt and Interface Customization in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- prompt
- tooling
- best-practices
---

_适用于 PowerShell 7.0 及以上版本_

每天在终端里敲命令数小时，默认的 `PS C:\>` 提示符只能告诉你当前路径，其他信息一概欠奉。当你在多个 Git 仓库之间切换、管理不同的 Azure 订阅、激活不同的 Python 虚拟环境时，一个信息丰富的提示符可以让你瞬间掌握上下文状态，减少低级错误。

PowerShell 的提示符本质上就是一个名为 `prompt` 的函数——你可以自由重写它。无论是显示 Git 分支和脏状态、上一次命令的执行耗时、当前用户权限级别，还是用颜色区分不同的服务器环境，都可以通过几行代码实现。本文将带你从手写 prompt 函数开始，再到集成 Oh My Posh 这类成熟框架，最后补充一套提升日常效率的实用工具函数。

<!-- more -->

## 手写自定义 prompt 函数

最直接的方式是重写 `prompt` 函数。下面这段代码实现了一个多行提示符，第一行显示时间、路径和 Git 状态，第二行是实际的输入光标。同时它还记录上一条命令的执行时间，方便你判断某个操作是否太慢。

```powershell
# 保存到 $PROFILE 中即可生效
# 记录命令开始时间
$global:__LastCommandStart = $null

# 在命令执行前记录时间
$ExecutionContext.SessionState.InvokeCommand.AddEventHandler(
    'CommandSearchAction', {
        $global:__LastCommandStart = [DateTime]::Now
    }
)

# 获取 Git 分支与状态信息
function Get-GitStatus {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) { return '' }

        $status = git status --porcelain 2>$null
        $dirty = if ($status) { '*' } else { '' }

        $ahead = git log "@{upstream}..HEAD" --oneline 2>$null
        $aheadCount = ($ahead | Where-Object { $_ }).Count

        $aheadMark = if ($aheadCount -gt 0) { "+$aheadCount" } else { '' }

        return " [$branch$dirty$aheadMark]"
    } catch {
        return ''
    }
}

# 获取上一次命令执行耗时
function Get-LastCommandDuration {
    if (-not $global:__LastCommandStart) { return '' }
    $duration = [DateTime]::Now - $global:__LastCommandStart
    if ($duration.TotalSeconds -gt 1) {
        return " ($([math]::Round($duration.TotalSeconds, 1))s)"
    }
    return ''
}

# 自定义 prompt 函数
function prompt {
    $path = Get-Location
    $homePrefix = $HOME -replace '\\', '\\'
    $displayPath = $path.Path -replace "^$homePrefix", '~'
    $gitInfo = Get-GitStatus
    $duration = Get-LastCommandDuration
    $timeStamp = Get-Date -Format 'HH:mm:ss'

    # 第一行：时间戳 + 路径 + Git 状态 + 执行耗时
    Write-Host "`n" -NoNewline
    Write-Host $timeStamp -ForegroundColor DarkGray -NoNewline
    Write-Host " " -NoNewline
    Write-Host $displayPath -ForegroundColor Cyan -NoNewline
    Write-Host $gitInfo -ForegroundColor Yellow -NoNewline
    Write-Host $duration -ForegroundColor DarkYellow -NoNewline

    # 权限提示
    if (
        $IsWindows -and
        ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    ) {
        Write-Host " [ADMIN]" -ForegroundColor Red -NoNewline
    }

    # 第二行：输入提示符
    Write-Host ""
    Write-Host ">" -ForegroundColor Green -NoNewline
    return ' '
}
```

执行后的终端效果如下（纯文本模拟）：

```
14:32:05 ~/projects/my-app [main*+2] (3.2s)
>
```

第一行显示了当前时间、相对主目录的路径、Git 分支名称（`main`）、脏标记（`*`表示有未提交的更改）、领先远程的提交数（`+2`）以及上一条命令耗时 3.2 秒。如果在管理员模式下运行，还会出现红色的 `[ADMIN]` 标记。

## 集成 Oh My Posh

手动写 prompt 函数虽然灵活，但维护成本不低——尤其是当你想要图标、颜色主题、多种 Segment（环境变量、云平台信息等）时。Oh My Posh 是一个跨 Shell 的提示符渲染引擎，配合 Nerd Font 可以实现非常精美的终端外观。

```powershell
# 安装 Oh My Posh（Windows 推荐使用 winget）
# winget install JanDeDobbeleer.OhMyPosh -s winget

# macOS / Linux 使用 Homebrew
# brew install jandedobbeleer/oh-my-posh/oh-my-posh

# 在 $PROFILE 中初始化 Oh My Posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" |
    Invoke-Expression

# 如果想使用自定义配置文件
# $ompConfig = Join-Path $HOME '.config' 'oh-my-posh' 'my-theme.omp.json'
# oh-my-posh init pwsh --config $ompConfig | Invoke-Expression

# 查看所有内置主题
Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter '*.omp.json' |
    Select-Object -ExpandProperty Name |
    Sort-Object

# 快速预览主题（逐个浏览）
function Show-PoshThemePreview {
    param([int]$Index = 0)

    $themes = Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter '*.omp.json' |
        Sort-Object Name
    $theme = $themes[$Index]
    Write-Host "Theme [$Index/$($themes.Count)]: $($theme.Name)" -ForegroundColor Cyan
    oh-my-posh init pwsh --config $theme.FullName | Invoke-Expression
}

# 导出当前配置并按需修改
function Export-PoshConfig {
    param(
        [string]$OutputPath = (Join-Path $HOME '.config' 'oh-my-posh')
    )

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $defaultConfig = Join-Path $env:POSH_THEMES_PATH 'jandedobbeleer.omp.json'
    Copy-Item $defaultConfig (Join-Path $OutputPath 'my-theme.omp.json') -Force
    Write-Host "配置已导出到 $OutputPath\my-theme.omp.json" -ForegroundColor Green
    Write-Host '修改后更新 $PROFILE 中的 init 命令指向新文件即可。'
}
```

执行 `Get-ChildItem` 查看主题列表的部分输出：

```
1_shell.omp.json
agnoster.omp.json
agnosterplus.omp.json
atomic.omp.json
atomicBit.omp.json
...（共 100+ 内置主题）
```

执行 `Export-PoshConfig` 的输出：

```
配置已导出到 C:\Users\victor\.config\oh-my-posh\my-theme.omp.json
修改后更新 $PROFILE 中的 init 命令指向新文件即可。
```

Oh My Posh 的 JSON 配置文件支持丰富的 Segment 类型——Git、Az（Azure）、Python、Node、Docker、Kubectl 等等，你可以按需启用或禁用，调整颜色和图标。推荐从默认主题复制一份然后逐步微调，而不是从零开始编写。

## 实用工具函数集

提示符之外，Profile 里还可以放一些高频使用的辅助函数，它们与提示符配合让日常操作更加流畅。下面这组函数涵盖了目录快速跳转、增强的命令历史搜索，以及别名管理。

```powershell
# --- 目录快速跳转 ---
# 使用书签机制在常用目录间跳转
$global:DirectoryBookmarks = @{}

function Set-Bookmark {
    param([string]$Name)
    $global:DirectoryBookmarks[$Name] = (Get-Location).Path
    Write-Host "书签 '$Name' 已保存: $($global:DirectoryBookmarks[$Name])" -ForegroundColor Green
}

function Enter-Bookmark {
    param([string]$Name)
    if ($global:DirectoryBookmarks.ContainsKey($Name)) {
        Set-Location $global:DirectoryBookmarks[$Name]
    } else {
        Write-Warning "书签 '$Name' 不存在。已保存的书签："
        $global:DirectoryBookmarks.GetEnumerator() |
            ForEach-Object { Write-Host "  $($_.Key) => $($_.Value)" }
    }
}

# 简写别名
Set-Alias -Name bm -Value Set-Bookmark
Set-Alias -Name gb -Value Enter-Bookmark

# --- 增强的历史搜索 ---
# 使用 fzf（可选）或 PSFzf 模块进行模糊搜索
# 这里提供一个不依赖外部工具的方案
function Search-History {
    param([string]$Pattern = '*')

    Get-Content (Get-PSReadlineOption).HistorySavePath |
        Where-Object { $_ -like "*$Pattern*" } |
        Select-Object -Unique -Last 20
}

Set-Alias -Name hh -Value Search-History

# --- 别名管理 ---
# 列出所有自定义别名及其来源
function Get-MyAliases {
    $builtIn = Get-Alias |
        Where-Object { $_.Options -notcontains 'UserDefined' } |
        Select-Object -ExpandProperty Name

    Get-Alias |
        Where-Object { $_.Name -notin $builtIn } |
        Select-Object Name, Definition, Source |
        Sort-Object Name |
        Format-Table -AutoSize
}

# 快速进入 Profile 编辑模式
function Edit-Profile {
    param([switch]$OpenFolder)
    if ($OpenFolder) {
        Invoke-Item (Split-Path $PROFILE)
    } else {
        code $PROFILE
    }
}

Set-Alias -Name ep -Value Edit-Profile
```

使用书签功能的交互示例：

```
PS ~/projects/my-app> bm work
书签 'work' 已保存: /Users/victor/projects/my-app

PS ~> gb work
PS /Users/victor/projects/my-app>

PS ~> hh git
git status
git log --oneline -10
git push origin main
```

书签机制不依赖外部工具，设置简单，适合在少数几个高频目录之间切换。如果你的目录结构比较复杂，也可以考虑搭配 `z` 或 `zoxide` 这类基于频率的跳转工具使用。

## 注意事项

1. **prompt 函数必须返回字符串**：即使你只用 `Write-Host` 输出内容，函数也必须 `return` 一个字符串（哪怕是一个空格或空字符串），否则 PowerShell 会使用默认的提示符。
2. **Git 状态检测有性能开销**：在大型仓库中，`git status --porcelain` 可能较慢。如果感到提示符延迟，可以在 `Get-GitStatus` 中加一个超时判断，或改用 `git diff --quiet` 做轻量级检测。
3. **Oh My Posh 需要 Nerd Font**：图标符号依赖 Nerd Font 字体。如果终端中看到方框或乱码，说明字体未正确安装。推荐使用 `CaskaydiaCove Nerd Font` 或 `FiraCode Nerd Font`。
4. **Profile 分模块管理**：随着自定义内容增多，建议把 prompt、别名、函数拆到不同的 `.ps1` 文件中，在 `$PROFILE` 里用 `. $path` 点源加载，保持主文件简洁。
5. **跨平台兼容性**：本文代码同时适配 Windows、macOS 和 Linux，但管理员检测部分（`[Security.Principal.WindowsIdentity]`）只在 Windows 上生效，非 Windows 平台会自动跳过该逻辑。
6. **PSReadLine 是好搭档**：提示符定制之外，`Set-PSReadlineOption` 可以配置预测文本来源、颜色主题和快捷键。结合 `CommandPrediction` 插件，终端体验可以接近 IDE 级别。
