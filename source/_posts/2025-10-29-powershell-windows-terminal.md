---
layout: post
date: 2025-10-29 08:00:00
updated: 2025-10-29 08:00:00
title: "PowerShell 技能连载 - Windows Terminal 定制"
description: PowerTip of the Day - Windows Terminal Customization in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- windows
- best-practices
- tooling
- profile
---

_适用于 PowerShell 7.0 及以上版本_

Windows Terminal 已经成为 Windows 平台上最受欢迎的终端模拟器之一。它支持多标签页、GPU 加速渲染、Unicode 和 UTF-8 字符显示，以及对 WSL、CMD、PowerShell 等多种 Shell 的统一管理。但对于日常重度使用命令行的开发者来说，默认的 Terminal 外观和功能往往不够用——提示符单调、配色平庸、缺少上下文信息，这些都会影响工作效率。

好消息是，借助 PowerShell 7 的强大生态，我们可以通过 Oh My Posh 主题引擎、Profile 脚本自动化以及 Terminal 的 JSON 配置，打造一个既美观又实用的终端环境。从 Git 状态感知的提示符，到一键切换配色方案，再到自定义快捷键绑定，几乎所有的视觉和行为要素都可以按需调整。

本文将从实际场景出发，逐步展示如何用 PowerShell 脚本完成 Windows Terminal 的深度定制。每一段代码都可以直接复制到你的环境中运行，让你在几分钟内拥有一个令人印象深刻的终端工作区。

<!-- more -->

## 安装和初始化 Oh My Posh

Oh My Posh 是一个跨平台的提示符主题引擎，可以为 PowerShell 提供丰富的上下文信息，包括 Git 分支状态、Python 虚拟环境、执行耗时等。首先我们需要安装它并配置到 Profile 中。

```powershell
# 安装 Oh My Posh（使用 winget）
winget install JanDeDobbeleer.OhMyPosh -s winget

# 如果 winget 不可用，也可以用 PowerShell 直接安装
Install-Module oh-my-posh -Scope CurrentUser -Force

# 查看 Oh My Posh 版本确认安装成功
oh-my-posh --version
```

安装完成后，输出类似如下：

```
24.5.0
```

接下来将 Oh My Posh 初始化命令写入 Profile，使其在每次启动 PowerShell 时自动加载：

```powershell
# 查找或创建 Profile 文件
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) {
    $null = New-Item -Path $profilePath -ItemType File -Force
    Write-Host "已创建 Profile 文件: $profilePath"
} else {
    Write-Host "Profile 文件已存在: $profilePath"
}

# 向 Profile 中追加 Oh My Posh 初始化行
$initLine = 'oh-my-posh init pwsh | Invoke-Expression'
$content = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
if ($content -notmatch 'oh-my-posh init') {
    Add-Content -Path $profilePath -Value $initLine
    Write-Host '已添加 Oh My Posh 初始化命令'
} else {
    Write-Host 'Oh My Posh 初始化命令已存在，跳过'
}
```

执行结果示例：

```
已创建 Profile 文件: C:\Users\dev\Documents\PowerShell\profile.ps1
已添加 Oh My Posh 初始化命令
```

## 浏览和应用主题

Oh My Posh 内置了大量开箱即用的主题，你可以通过脚本快速预览并切换。以下代码列出所有可用主题，并让你预览效果。

```powershell
# 获取 Oh My Posh 主题目录
$themesDir = "$(oh-my-posh config export themes)"

# 列出所有主题文件名
$themes = Get-ChildItem -Path $themesDir -Filter '*.omp.json' |
    Select-Object -ExpandProperty BaseName

Write-Host "共找到 $($themes.Count) 个主题"
Write-Host '---'
foreach ($t in $themes) {
    Write-Host "  - $t"
}
```

执行结果示例：

```
共找到 127 个主题
---
  - 1_shell
  - agnoster
  - agnosterplus
  - aliens
  - amro
  - atomic
  - atomicBit
  - avit
  ...
```

找到喜欢的主题后，将其写入 Profile：

```powershell
# 选择主题名称
$selectedTheme = 'jandebuhr'

# 构建 Oh My Posh 初始化命令（指定主题）
$themeInit = "oh-my-posh init pwsh --config `"$themesDir\$selectedTheme.omp.json`" | Invoke-Expression"

# 读取当前 Profile 内容
$profileContent = Get-Content -Path $PROFILE.CurrentUserAllHosts -Raw

# 替换已有的 oh-my-posh init 行，或追加新行
if ($profileContent -match 'oh-my-posh init pwsh') {
    $profileContent = $profileContent -replace 'oh-my-posh init pwsh.*Invoke-Expression', $themeInit
    Set-Content -Path $PROFILE.CurrentUserAllHosts -Value $profileContent -NoNewline
    Write-Host "已更新主题为: $selectedTheme"
} else {
    Add-Content -Path $PROFILE.CurrentUserAllHosts -Value $themeInit
    Write-Host "已添加主题: $selectedTheme"
}

Write-Host '请重新打开终端以查看效果'
```

执行结果示例：

```
已更新主题为: jandebuhr
请重新打开终端以查看效果
```

## 自动化管理 Terminal 配置文件

Windows Terminal 的设置存储在一个 JSON 文件中，路径通常是 `settings.json`。我们可以用 PowerShell 脚本直接读取和修改它，实现配色方案的批量管理和快捷键自定义。

```powershell
# 定位 Windows Terminal settings.json 路径
$settingsPath = Join-Path -Path $env:LOCALAPPDATA `
    -ChildPath 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

# 如果是 Preview 版本
if (-not (Test-Path $settingsPath)) {
    $settingsPath = Join-Path -Path $env:LOCALAPPDATA `
        -ChildPath 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
}

# 备份原始配置
$backupPath = $settingsPath + '.backup'
Copy-Item -Path $settingsPath -Destination $backupPath -Force
Write-Host "已备份配置到: $backupPath"

# 读取并解析 JSON
$settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
Write-Host "当前共有 $(($settings.schemes | Measure-Object).Count) 个配色方案"
```

执行结果示例：

```
已备份配置到: C:\Users\dev\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.backup
当前共有 24 个配色方案
```

下面演示如何通过脚本添加自定义配色方案：

```powershell
# 定义一个新的配色方案
$newScheme = @{
    name         = 'PowerShell Dark Modern'
    background   = '#0C0C0C'
    foreground   = '#CCCCCC'
    cursorColor  = '#00FF00'
    black        = '#0C0C0C'
    blue         = '#0037DA'
    cyan         = '#3A96DD'
    green        = '#13A10E'
    purple       = '#881798'
    red          = '#C50F1F'
    white        = '#CCCCCC'
    yellow       = '#C19C00'
    brightBlack  = '#767676'
    brightBlue   = '#3B78FF'
    brightCyan   = '#61D6D6'
    brightGreen  = '#16C60C'
    brightPurple = '#B4009E'
    brightRed    = '#E74856'
    brightWhite  = '#F2F2F2'
    brightYellow = '#F9F1A5'
}

# 将哈希表转换为 PSCustomObject 并添加到 schemes 数组
$schemeObj = [PSCustomObject]$newScheme

if (-not $settings.schemes) {
    $settings | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @()
}
$settings.schemes += $schemeObj

# 将指定 Profile 的配色方案设置为新建的方案
foreach ($profile in $settings.profiles.list) {
    if ($profile.name -match 'PowerShell') {
        $profile | Add-Member -MemberType NoteProperty -Name 'colorScheme' `
            -Value 'PowerShell Dark Modern' -Force
        Write-Host "已为 Profile '$($profile.name)' 应用新配色"
    }
}

# 写回 settings.json
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host '配置已保存，重新打开 Terminal 即可看到效果'
```

执行结果示例：

```
已为 Profile 'Windows PowerShell' 应用新配色
已为 Profile 'PowerShell 7' 应用新配色
配置已保存，重新打开 Terminal 即可看到效果
```

## 在 Profile 中添加实用函数

一个精心定制的终端不仅仅是好看，更要好用。以下是一组可以直接加入 Profile 的实用函数，提升日常操作效率。

```powershell
# 这段代码演示如何向 Profile 中批量添加实用函数
$functions = @(
    @{
        Name = 'Get-TerminalVersion'
        Code = @'
function Get-TerminalVersion {
    <# 获取当前 Windows Terminal 版本 #>
    $pkg = Get-AppxPackage *WindowsTerminal*
    if ($pkg) {
        [PSCustomObject]@{
            Name    = $pkg.Name
            Version = $pkg.Version
            Status  = '已安装'
        }
    } else {
        Write-Warning '未检测到 Windows Terminal 安装'
    }
}
'@
    }
    @{
        Name = 'Export-TerminalSettings'
        Code = @'
function Export-TerminalSettings {
    <# 导出 Windows Terminal 配置到桌面 #>
    $dest = Join-Path $env:USERPROFILE 'Desktop\wt-settings-backup.json'
    $src = Join-Path $env:LOCALAPPDATA `
        'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dest -Force
        Write-Host "配置已导出到: $dest"
    } else {
        Write-Warning '未找到 Windows Terminal 配置文件'
    }
}
'@
    }
    @{
        Name = 'Set-TerminalOpacity'
        Code = @'
function Set-TerminalOpacity {
    <# 设置 Terminal 窗口透明度（需要 Terminal 设置中启用亚克力效果）#>
    param([int]$Opacity = 80)
    $settingsPath = Join-Path $env:LOCALAPPDATA `
        'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    foreach ($p in $settings.profiles.list) {
        $p | Add-Member -MemberType NoteProperty -Name 'opacity' `
            -Value $Opacity -Force
    }
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "已将所有 Profile 透明度设置为 ${Opacity}%"
}
'@
    }
)

# 写入 Profile
$profileFile = $PROFILE.CurrentUserAllHosts
foreach ($func in $functions) {
    if (-not (Select-String -Path $profileFile -Pattern "function $($func.Name)" -Quiet)) {
        Add-Content -Path $profileFile -Value "`n$($func.Code)"
        Write-Host "已添加函数: $($func.Name)"
    } else {
        Write-Host "函数已存在，跳过: $($func.Name)"
    }
}
```

执行结果示例：

```
已添加函数: Get-TerminalVersion
已添加函数: Export-TerminalSettings
已添加函数: Set-TerminalOpacity
```

添加完成后，重新加载 Profile 即可使用这些函数：

```powershell
. $PROFILE.CurrentUserAllHosts

# 测试获取 Terminal 版本
Get-TerminalVersion
```

```
Name                            Version        Status
----                            -------        ------
Microsoft.WindowsTerminal       1.22.11141.0   已安装
```

## 注意事项

1. **备份配置再修改**：Terminal 的 `settings.json` 是唯一配置来源，修改前务必备份。本文中的脚本会自动创建 `.backup` 副本，但建议你也定期将配置纳入版本控制。

2. **Oh My Posh 字体依赖**：大部分 Oh My Posh 主题需要 Nerd Font 字体才能正确显示图标。推荐安装 `CascadiaCode` 或 `FiraCode` 的 Nerd Font 版本，并在 Terminal 设置中将字体名填入 Profile 的 `font.face` 字段。

3. **Profile 执行策略**：如果系统执行策略禁止运行脚本，Oh My Posh 和自定义函数都不会生效。需要以管理员身份执行 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` 来放行本地脚本。

4. **JSON 序列化深度**：`ConvertTo-Json` 默认深度为 2，Terminal 的 `settings.json` 嵌套较深（特别是 `actions` 数组），务必使用 `-Depth 10` 或更高，否则部分配置会丢失。

5. **Preview 和 Stable 版本路径不同**：Windows Terminal Preview 版的包名包含 `Preview`，`settings.json` 的路径也不同。脚本中应同时检测两个路径，避免修改错目标。

6. **亚克力效果和透明度需要 GPU 支持**：`useAcrylic` 和 `opacity` 设置依赖 GPU 加速渲染。在虚拟机或远程桌面会话中，这些视觉效果可能无法正常工作，但不影响核心功能使用。
