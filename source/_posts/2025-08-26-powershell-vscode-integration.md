---
layout: post
date: 2025-08-26 08:00:00
updated: 2025-08-26 08:00:00
title: "PowerShell 技能连载 - VS Code 工作区自动化"
description: PowerTip of the Day - VS Code Workspace Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- vscode
- automation
- ide
---

_适用于 PowerShell 5.1 及以上版本_

VS Code 是 PowerShell 开发者最常用的编辑器，但很多人不知道 PowerShell 可以自动化 VS Code 的各种操作——批量生成工作区配置、管理扩展、操控编辑器行为、甚至通过 VS Code 的命令行接口实现自动化编辑。结合 PowerShell 的脚本能力，可以大幅提升 VS Code 的使用效率，特别是在团队协作中统一开发环境配置。

本文将讲解如何通过 PowerShell 自动化 VS Code 的工作区和配置管理。

<!-- more -->

## VS Code 命令行操作

```powershell
# 检查 VS Code 是否安装
function Test-VSCodeInstalled {
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) {
        $version = & code --version 2>$null | Select-Object -First 1
        Write-Host "VS Code 已安装：$version" -ForegroundColor Green
        return $true
    }
    Write-Host "VS Code 未安装" -ForegroundColor Red
    return $false
}

Test-VSCodeInstalled

# 打开项目
function Open-VSCodeProject {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$NewWindow
    )

    $args = @()
    if ($NewWindow) { $args += "--new-window" }
    $args += $Path

    Start-Process "code" -ArgumentList $args
    Write-Host "已打开 VS Code：$Path" -ForegroundColor Green
}

Open-VSCodeProject -Path "C:\Projects\MyApp"

# 打开特定文件并跳转到行
function Open-VSCodeFile {
    param(
        [Parameter(Mandatory)][string]$File,
        [int]$LineNumber,
        [int]$Column
    )

    $args = @($File)
    if ($LineNumber) {
        $goto = if ($Column) { "${LineNumber}:${Column}" } else { "$LineNumber" }
        $args += "--goto", $goto
    }

    Start-Process "code" -ArgumentList $args
    Write-Host "已打开：$File$(if ($LineNumber) { ":$LineNumber" })" -ForegroundColor Green
}

# 比较文件差异
function Compare-VSCodeFiles {
    param([string]$File1, [string]$File2)
    Start-Process "code" -ArgumentList "--diff", $File1, $File2
    Write-Host "正在比较：$File1 vs $File2" -ForegroundColor Cyan
}
```

执行结果示例：

```
VS Code 已安装：1.90.1
已打开 VS Code：C:\Projects\MyApp
已打开：C:\Scripts\deploy.ps1:42
正在比较：config-old.json vs config-new.json
```

## 扩展管理

```powershell
# 列出已安装扩展
function Get-VSCodeExtensions {
    $output = & code --list-extensions 2>$null
    $extensions = $output | ForEach-Object {
        $parts = $_ -split '@'
        [PSCustomObject]@{
            Id      = $parts[0]
            Version = if ($parts.Count -gt 1) { $parts[1] } else { "latest" }
        }
    }
    return $extensions
}

$exts = Get-VSCodeExtensions
Write-Host "已安装扩展：$($exts.Count) 个" -ForegroundColor Cyan
$exts | Format-Table -AutoSize

# PowerShell 开发推荐扩展
$recommendedExtensions = @(
    "ms-vscode.powershell",           # PowerShell 官方扩展
    "dbaeumer.vscode-eslint",         # ESLint
    "eamodio.gitlens",                # Git 增强
    "ms-azuretools.vscode-docker",    # Docker
    "ms-vscode-remote.remote-ssh",    # 远程 SSH
    "redhat.vscode-yaml",             # YAML 支持
    "ms-vscode.json-stable-stringify" # JSON 工具
)

# 批量安装扩展
function Install-VSCodeExtensions {
    param([string[]]$Extensions)

    foreach ($ext in $Extensions) {
        Write-Host "安装 $ext..." -ForegroundColor Cyan -NoNewline
        & code --install-extension $ext 2>$null | Out-Null
        Write-Host " 完成" -ForegroundColor Green
    }
    Write-Host "`n扩展安装完成" -ForegroundColor Green
}

Install-VSCodeExtensions -Extensions $recommendedExtensions

# 导出扩展列表（团队共享）
function Export-VSCodeExtensions {
    param([string]$OutputPath = ".vscode\extensions.txt")

    $dir = Split-Path $OutputPath -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item $dir -ItemType Directory -Force | Out-Null
    }

    $extensions = Get-VSCodeExtensions
    $extensions.Id | Set-Content $OutputPath -Encoding UTF8
    Write-Host "已导出 $($extensions.Count) 个扩展到 $OutputPath" -ForegroundColor Green
}

Export-VSCodeExtensions
```

执行结果示例：

```
已安装扩展：15 个
Id                                    Version
--                                    -------
ms-vscode.powershell                  2024.1.0
eamodio.gitlens                       15.0.0
dbaeumer.vscode-eslint                2.4.4

安装 ms-vscode.powershell... 完成
安装 eamodio.gitlens... 完成
安装 ms-azuretools.vscode-docker... 完成
扩展安装完成

已导出 15 个扩展到 .vscode\extensions.txt
```

## 工作区配置管理

```powershell
# 生成 VS Code 工作区配置
function New-VSCodeWorkspace {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [string]$ProjectName = (Split-Path $ProjectPath -Leaf)
    )

    $vscodeDir = Join-Path $ProjectPath ".vscode"
    New-Item $vscodeDir -ItemType Directory -Force | Out-Null

    # settings.json
    $settings = @{
        "powershell.scriptAnalysis.enable"       = $true
        "powershell.codeFormatting.preset"       = "OTBS"
        "files.encoding"                         = "utf8"
        "files.autoSave"                         = "afterDelay"
        "files.autoSaveDelay"                    = 1000
        "editor.formatOnSave"                    = $true
        "editor.tabSize"                         = 4
        "terminal.integrated.defaultProfile.windows" = "PowerShell"
        "git.autofetch"                          = $true
    }

    $settings | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $vscodeDir "settings.json") -Encoding UTF8

    # launch.json（调试配置）
    $launch = @{
        version = "0.2.0"
        configurations = @(
            @{
                type       = "PowerShell"
                request    = "launch"
                name       = "PowerShell Launch Script"
                script     = '${file}'
                args       = @()
                cwd        = '${fileDirname}'
            },
            @{
                type       = "PowerShell"
                request    = "attach"
                name       = "PowerShell Attach to Process"
                processId  = '${command:pickProcess}'
            }
        )
    }

    $launch | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $vscodeDir "launch.json") -Encoding UTF8

    # extensions.json（推荐扩展）
    $recommendations = @{
        recommendations = @(
            "ms-vscode.powershell",
            "eamodio.gitlens",
            "redhat.vscode-yaml"
        )
    }

    $recommendations | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $vscodeDir "extensions.json") -Encoding UTF8

    Write-Host "VS Code 工作区配置已生成：$ProjectPath" -ForegroundColor Green
    Write-Host "  settings.json - 编辑器设置" -ForegroundColor Cyan
    Write-Host "  launch.json - 调试配置" -ForegroundColor Cyan
    Write-Host "  extensions.json - 推荐扩展" -ForegroundColor Cyan
}

New-VSCodeWorkspace -ProjectPath "C:\Projects\MyApp"

# 生成任务配置
function New-VSCodeTasks {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath
    )

    $tasks = @{
        version = "2.0.0"
        tasks   = @(
            @{
                label    = "Run Pester Tests"
                type     = "shell"
                command  = "pwsh"
                args     = @("-Command", "Invoke-Pester -Path './tests/' -Output Detailed")
                group    = @{ kind = "test"; isDefault = $true }
                problemMatcher = @()
            },
            @{
                label   = "Lint Scripts"
                type    = "shell"
                command = "pwsh"
                args    = @("-Command", "Get-ChildItem -Filter '*.ps1' -Recurse | ForEach-Object { Invoke-ScriptAnalyzer `$_ }")
                group   = "build"
            },
            @{
                label       = "Build Module"
                type        = "shell"
                command     = "pwsh"
                args        = @("./build.ps1")
                group       = @{ kind = "build"; isDefault = $true }
                dependsOn   = @("Lint Scripts")
            }
        )
    }

    $tasks | ConvertTo-Json -Depth 5 |
        Set-Content (Join-Path $ProjectPath ".vscode\tasks.json") -Encoding UTF8
    Write-Host "任务配置已生成" -ForegroundColor Green
}

New-VSCodeTasks -ProjectPath "C:\Projects\MyApp"
```

执行结果示例：

```
VS Code 工作区配置已生成：C:\Projects\MyApp
  settings.json - 编辑器设置
  launch.json - 调试配置
  extensions.json - 推荐扩展
任务配置已生成
```

## 批量项目初始化

```powershell
# 团队项目批量初始化
function Initialize-TeamProject {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [string]$ProjectName = (Split-Path $ProjectPath -Leaf)
    )

    Write-Host "初始化项目：$ProjectName" -ForegroundColor Cyan

    # 创建目录结构
    $dirs = @("source", "source\Public", "source\Private", "tests", "docs", ".vscode")
    foreach ($dir in $dirs) {
        New-Item (Join-Path $ProjectPath $dir) -ItemType Directory -Force | Out-Null
    }

    # 生成 VS Code 配置
    New-VSCodeWorkspace -ProjectPath $ProjectPath
    New-VSCodeTasks -ProjectPath $ProjectPath

    # 生成 .gitignore
    $gitignore = @"
.vscode/
*.user
*.suo
bin/
obj/
packages/
TestResults/
"@
    $gitignore | Set-Content (Join-Path $ProjectPath ".gitignore") -Encoding UTF8

    # 初始化 Git
    Push-Location $ProjectPath
    git init 2>$null
    git add -A 2>$null
    git commit -m "Initial project setup" 2>$null
    Pop-Location

    Write-Host "项目初始化完成：$ProjectName" -ForegroundColor Green
}

Initialize-TeamProject -ProjectPath "C:\Projects\NewModule" -ProjectName "NewModule"
```

执行结果示例：

```
初始化项目：NewModule
VS Code 工作区配置已生成：C:\Projects\NewModule
任务配置已生成
项目初始化完成：NewModule
```

## 注意事项

1. **code 命令路径**：如果 `code` 命令不在 PATH 中，使用完整路径或通过 VS Code 的 "Shell Command: Install 'code' command in PATH" 安装
2. **settings 层级**：VS Code 设置分用户级和项目级，项目级设置放在 `.vscode/settings.json` 中
3. **扩展同步**：Settings Sync 功能可以跨设备同步扩展和设置，不需要手动导出
4. **工作区文件**：`.code-workspace` 文件可以管理多根工作区，适合 monorepo 项目
5. **任务依赖**：tasks.json 中可以用 `dependsOn` 定义任务依赖关系，实现构建流水线
6. **敏感信息**：`.vscode/settings.json` 可能包含本地路径等信息，加入 `.gitignore` 或使用变量
