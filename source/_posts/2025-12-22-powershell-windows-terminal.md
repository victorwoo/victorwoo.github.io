---
layout: post
date: 2025-12-22 08:00:00
updated: 2025-12-22 08:00:00
title: "PowerShell 技能连载 - Windows Terminal 自动化"
description: PowerTip of the Day - Windows Terminal Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- windows
- automation
---

_适用于 PowerShell 7.0 及以上版本_

Windows Terminal 自 2019 年发布以来，已经迅速成为 Windows 平台上最受欢迎的终端应用。它不仅支持多标签页、分屏布局、GPU 加速文本渲染，还提供了完善的 JSON 配置体系。对于系统运维工程师来说，每天启动工作环境时手动打开多个标签、连接不同服务器、调整窗口布局是一项重复且耗时的工作。

借助 PowerShell 对 JSON 配置文件的读写能力，以及 `wt.exe` 命令行工具的强大参数支持，我们可以将这套流程完全自动化——一条命令就能启动包含多个标签和分屏的完整工作环境。更进一步，还能批量管理配色方案、快捷键绑定等个性化配置，在团队内实现统一的工作环境标准化。

本文将围绕 Windows Terminal 的配置读取与修改、多标签分屏自动化启动、以及主题配色自定义三个方面，展示如何用 PowerShell 打造一套"开箱即用"的终端工作流。

<!-- more -->

## 读取和修改 Windows Terminal 配置

Windows Terminal 的所有配置存储在 `settings.json` 文件中。通过 PowerShell 可以方便地读取、解析和修改这些配置，实现配置的版本化管理或批量部署。

```powershell
function Get-WTSettings {
    <#
    .SYNOPSIS
    获取 Windows Terminal 的 settings.json 配置对象
    #>
    $settingsPath = Join-Path $env:LOCALAPPDATA `
        "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $settingsPath)) {
        # 兼容预览版路径
        $settingsPath = Join-Path $env:LOCALAPPDATA `
            "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    }

    if (-not (Test-Path $settingsPath)) {
        throw "未找到 Windows Terminal 配置文件"
    }

    $content = Get-Content -Path $settingsPath -Raw -Encoding UTF8
    # 去除 JSON 注释（简易处理）
    $cleanJson = $content -replace '(?m)//.*?$', ''
    $config = $cleanJson | ConvertFrom-Json
    return @{
        Config   = $config
        Path     = $settingsPath
        Raw      = $content
    }
}

function Set-WTDefaultProfile {
    <#
    .SYNOPSIS
    设置 Windows Terminal 的默认配置文件（Profile）
    .PARAMETER ProfileName
    要设为默认的配置文件名称，例如 "PowerShell 7"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName
    )

    $settings = Get-WTSettings
    $config = $settings.Config

    # 在 profiles.list 中查找目标配置
    $target = $config.profiles.list | Where-Object {
        $_.name -eq $ProfileName
    } | Select-Object -First 1

    if (-not $target) {
        throw "未找到名为 '$ProfileName' 的配置文件"
    }

    # 更新默认 Profile GUID
    $config.defaultProfile = $target.guid

    # 写回文件，保留可读格式
    $config | ConvertTo-Json -Depth 20 |
        Set-Content -Path $settings.Path -Encoding UTF8

    Write-Host "已将默认 Profile 设为: $ProfileName ($($target.guid))"
}

# 示例：列出所有可用的 Profile
$settings = Get-WTSettings
$settings.Config.profiles.list | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.name
        GUID = $_.guid
        Hidden = $_.hidden
    }
} | Format-Table -AutoSize

# 示例：将 PowerShell 7 设为默认终端
Set-WTDefaultProfile -ProfileName "PowerShell 7"
```

执行结果示例：

```
Name                       GUID                                 Hidden
----                       ----                                 ------
PowerShell 7               {574e775e-4f2a-5b96-ac1e-a2962a402336} False
Command Prompt             {0caa0dad-35be-5f56-a8ff-afceeeaa6101} False
Windows PowerShell         {61c54bbd-c2c6-5271-96e7-009a87ff44bf} False
Azure Cloud Shell          {b453cfc9-5a51-5a7e-889c-f8e96be50e27} True
Ubuntu (WSL)               {2c4de342-38b7-51cf-b940-2309a097f518} False

已将默认 Profile 设为: PowerShell 7 ({574e775e-4f2a-5b96-ac1e-a2962a402336})
```

## 自动化启动多标签分屏布局

Windows Terminal 提供了 `wt.exe` 命令行工具，支持通过参数指定标签页、分屏布局和启动命令。我们可以封装一个 PowerShell 函数，实现一键启动包含多个服务器连接的完整运维工作台。

```powershell
function Start-WTOpsWorkbench {
    <#
    .SYNOPSIS
    一键启动运维工作台：自动打开多个标签页和分屏窗格
    .PARAMETER Environment
    目标环境名称：dev / staging / production
    #>
    param(
        [ValidateSet("dev", "staging", "production")]
        [string]$Environment = "dev"
    )

    # 定义各环境的服务器列表
    $envConfig = @{
        dev = @{
            servers = @("dev-web-01", "dev-db-01")
            profile = "PowerShell 7"
        }
        staging = @{
            servers = @("stg-web-01", "stg-web-02", "stg-db-01")
            profile = "PowerShell 7"
        }
        production = @{
            servers = @("prod-web-01", "prod-web-02", "prod-db-01", "prod-monitor")
            profile = "PowerShell 7"
        }
    }

    $config = $envConfig[$Environment]
    $servers = $config.servers
    $profile = $config.profile

    # 构建 wt.exe 参数
    $wtArgs = @()

    # 第一个标签：本地 PowerShell + 系统监控
    $wtArgs += "-p"
    $wtArgs += "`"$profile`""
    $wtArgs += ";"
    $wtArgs += "split-pane"
    $wtArgs += "-V"
    $wtArgs += "-p"
    $wtArgs += "`"$profile`""
    $wtArgs += "--"
    $wtArgs += "pwsh"
    $wtArgs += "-NoExit"
    $wtArgs += "-Command"
    $wtArgs += '"Write-Host \"[系统监控] 本地环境\" -ForegroundColor Cyan; Get-Process | Sort-Object CPU -Descending | Select-Object -First 10"'

    # 后续标签：每台服务器一个标签
    foreach ($server in $servers) {
        $wtArgs += ";"
        $wtArgs += "new-tab"
        $wtArgs += "-p"
        $wtArgs += "`"$profile`""
        $wtArgs += "--"
        $wtArgs += "pwsh"
        $wtArgs += "-NoExit"
        $wtArgs += "-Command"
        $wtArgs += "\"Enter-PSSession -ComputerName $server -ConfigurationName PowerShell.7\""
    }

    # 最后一个标签：日志查看
    $wtArgs += ";"
    $wtArgs += "new-tab"
    $wtArgs += "-p"
    $wtArgs += "`"$profile`""
    $wtArgs += "--"
    $wtArgs += "pwsh"
    $wtArgs += "-NoExit"
    $wtArgs += "-Command"
    $wtArgs += '"Write-Host \"[日志中心] $Environment 环境\" -ForegroundColor Yellow; Get-Content \\logserver\logs\app.log -Tail 50 -Wait"'

    Write-Host "正在启动 $Environment 环境运维工作台..." -ForegroundColor Green
    Write-Host "  服务器: $($servers -join ', ')" -ForegroundColor Gray
    Write-Host "  标签数: $($servers.Count + 2)" -ForegroundColor Gray

    Start-Process -FilePath "wt.exe" -ArgumentList $wtArgs
}

# 一键启动开发环境工作台
Start-WTOpsWorkbench -Environment dev

# 启动生产环境工作台
# Start-WTOpsWorkbench -Environment production
```

执行结果示例：

```
正在启动 dev 环境运维工作台...
  服务器: dev-web-01, dev-db-01
  标签数: 4
```

此时 Windows Terminal 会自动打开，包含 4 个标签页：第一个标签上下分屏显示本地 PowerShell 和系统监控，第二个标签通过 `Enter-PSSession` 连接 `dev-web-01`，第三个标签连接 `dev-db-01`，第四个标签实时跟踪日志文件。

## 自定义主题配色与快捷操作

Windows Terminal 的配色方案（Color Scheme）和快捷键绑定（Keybindings / Actions）同样存储在 `settings.json` 中。我们可以用 PowerShell 批量创建自定义主题，并配置实用的快捷操作，甚至将这些配置导出给团队成员使用。

```powershell
function Add-WTColorScheme {
    <#
    .SYNOPSIS
    向 Windows Terminal 添加自定义配色方案
    .PARAMETER Name
    配色方案名称
    .PARAMETER Style
    预设风格：Dracula / Solarized / Nord / TokyoNight
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [ValidateSet("Dracula", "Solarized", "Nord", "TokyoNight")]
        [string]$Style = "Dracula"
    )

    $presets = @{
        Dracula = @{
            "background"  = "#282a36"
            "foreground"  = "#f8f8f2"
            "cursorColor" = "#f8f8f2"
            "black"       = "#21222c"
            "red"         = "#ff5555"
            "green"       = "#50fa7b"
            "yellow"      = "#f1fa8c"
            "blue"        = "#bd93f9"
            "purple"      = "#ff79c6"
            "cyan"        = "#8be9fd"
            "white"       = "#f8f8f2"
            "brightBlack" = "#6272a4"
            "brightRed"   = "#ff6e6e"
            "brightGreen" = "#69ff94"
            "brightYellow"= "#ffffa5"
            "brightBlue"  = "#d6acff"
            "brightPurple"= "#ff92df"
            "brightCyan"  = "#a4ffff"
            "brightWhite" = "#ffffff"
        }
        Nord = @{
            "background"  = "#2e3440"
            "foreground"  = "#d8dee9"
            "cursorColor" = "#d8dee9"
            "black"       = "#3b4252"
            "red"         = "#bf616a"
            "green"       = "#a3be8c"
            "yellow"      = "#ebcb8b"
            "blue"        = "#81a1c1"
            "purple"      = "#b48ead"
            "cyan"        = "#88c0d0"
            "white"       = "#e5e9f0"
            "brightBlack" = "#4c566a"
            "brightRed"   = "#bf616a"
            "brightGreen" = "#a3be8c"
            "brightYellow"= "#ebcb8b"
            "brightBlue"  = "#81a1c1"
            "brightPurple"= "#b48ead"
            "brightCyan"  = "#8fbcbb"
            "brightWhite" = "#eceff4"
        }
    }

    $settings = Get-WTSettings
    $config = $settings.Config
    $rawJson = $settings.Raw

    $scheme = $presets[$Style]
    $scheme["name"] = $Name

    # 将新配色方案追加到 schemes 数组
    $schemeJson = $scheme | ConvertTo-Json -Depth 5
    $newSchemesJson = $rawJson -replace \
        '"schemes"\s*:\s*\[', `
        ("`"schemes`": [$schemeJson,")

    Set-Content -Path $settings.Path -Value $newSchemesJson -Encoding UTF8
    Write-Host "已添加配色方案: $Name ($Style 风格)" -ForegroundColor Green
}

function Export-WTThemeConfig {
    <#
    .SYNOPSIS
    导出当前 Windows Terminal 的配色方案为独立 JSON 文件，方便团队共享
    .PARAMETER OutputPath
    导出文件路径
    #>
    param(
        [string]$OutputPath = ".\wt-colorschemes.json"
    )

    $settings = Get-WTSettings
    $schemes = $settings.Config.schemes

    $schemes | ConvertTo-Json -Depth 10 |
        Set-Content -Path $OutputPath -Encoding UTF8

    Write-Host "已导出 $($schemes.Count) 个配色方案到: $OutputPath" -ForegroundColor Green

    # 列出所有配色方案名称
    $schemes | ForEach-Object {
        "  - $($_.name)"
    } | Write-Host
}

function Set-WTQuickActions {
    <#
    .SYNOPSIS
    向 Windows Terminal 添加实用快捷操作
    #>

    $quickActions = @(
        @{
            command = "splitPane"
            name = "水平分屏"
            keys = "ctrl+shift+bar"
        },
        @{
            command = @{
                action = "splitPane"
                split = "vertical"
            }
            name = "垂直分屏"
            keys = "ctrl+shift+plus"
        },
        @{
            command = @{
                action = "sendInput"
                input = "cls`r"
            }
            name = "快速清屏"
            keys = "ctrl+shift+k"
        }
    )

    $settings = Get-WTSettings
    $config = $settings.Config

    # 追加快捷操作到 actions 列表
    foreach ($action in $quickActions) {
        # 检查是否已存在同名操作
        $existing = $config.actions | Where-Object {
            $_.name -eq $action.name
        }
        if (-not $existing) {
            $config.actions += $action
            Write-Host "  已添加快捷操作: $($action.name) [$($action.keys)]" -ForegroundColor Cyan
        } else {
            Write-Host "  已存在，跳过: $($action.name)" -ForegroundColor DarkGray
        }
    }

    $config | ConvertTo-Json -Depth 20 |
        Set-Content -Path $settings.Path -Encoding UTF8

    Write-Host "`n快捷操作配置完成" -ForegroundColor Green
}

# 添加 Dracula 风格配色方案
Add-WTColorScheme -Name "MyDracula" -Style Dracula

# 导出配色方案供团队使用
Export-WTThemeConfig -OutputPath ".\team-wt-colors.json"

# 添加快捷操作
Set-WTQuickActions
```

执行结果示例：

```
已添加配色方案: MyDracula (Dracula 风格)
已导出 6 个配色方案到: .\team-wt-colors.json
  - Campbell
  - Campbell Powershell
  - One Half Dark
  - One Half Light
  - Solarized Dark
  - MyDracula
  已添加快捷操作: 水平分屏 [ctrl+shift+bar]
  已添加快捷操作: 垂直分屏 [ctrl+shift+plus]
  已添加快捷操作: 快速清屏 [ctrl+shift+k]

快捷操作配置完成
```

## 注意事项

1. **配置文件备份**：修改 `settings.json` 前务必先备份原文件（`Copy-Item` 即可）。Windows Terminal 在运行时可能随时写入配置，建议在 Terminal 关闭状态下执行修改操作，避免文件被覆盖导致配置丢失。

2. **JSON 注释兼容性**：`settings.json` 中可能包含 `//` 注释，标准的 `ConvertFrom-Json` 不支持注释。示例中使用了简易的正则去除注释，对于复杂场景建议使用 `System.Text.Json` 的 `JsonNode` API（PowerShell 7.4+）或第三方模块处理。

3. **wt.exe 参数转义**：`wt.exe` 的命令行参数中，分号 `;` 是命令分隔符，双引号需要正确转义。在 PowerShell 中拼接参数时，注意内层引号与外层引号的嵌套关系，建议先用 `$wtArgs -join ' '` 输出完整命令行检查一遍再执行。

4. **Profile GUID 稳定性**：Windows Terminal 使用 GUID 标识每个 Profile，不同机器上的 GUID 可能不同。在脚本中应优先通过 Profile 名称（`name` 字段）查找，而非硬编码 GUID，确保脚本的可移植性。

5. **路径兼容性**：Windows Terminal 正式版和预览版的 `settings.json` 路径不同（包名包含 `WindowsTerminal` 或 `WindowsTerminalPreview`）。脚本中应同时检测两个路径，也可以通过 `Get-ChildItem` 在 `$env:LOCALAPPDATA\Packages` 下动态搜索。

6. **远程会话依赖**：使用 `Enter-PSSession` 连接远程服务器时，目标机器需要启用 WinRM 服务并配置好 PowerShell Remoting。生产环境中建议使用 JEA（Just Enough Administration）端点限制权限，并通过 `-ConfigurationName` 参数指定受限的会话配置。
