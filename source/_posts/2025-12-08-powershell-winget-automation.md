---
layout: post
date: 2025-12-08 08:00:00
title: "PowerShell 技能连载 - WinGet 包管理自动化"
description: PowerTip of the Day - WinGet Package Management Automation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- winget
- package-management
- windows
---

_适用于 PowerShell 7.0 及以上版本，需要 winget CLI_

## 背景介绍

在企业 IT 运维中，软件安装和更新是一项高频且重复的工作。新员工入职时需要配置开发环境，安全合规要求定期更新终端上的软件版本，这些都给运维团队带来了巨大的工作量。传统的手动安装方式不仅效率低下，还容易出现版本不一致、配置遗漏等问题。

WinGet（Windows Package Manager）是微软官方推出的命令行包管理工具，从 Windows 10 1709 版本开始内置。它提供了类似 Linux 下 apt 或 yum 的软件管理体验，支持搜索、安装、更新和卸载应用程序。结合 PowerShell 的脚本能力，我们可以将 WinGet 的操作封装为可复用的自动化流程。

本文将通过三个实际场景，演示如何使用 PowerShell 调用 WinGet 实现软件搜索安装、批量部署以及自动化更新，帮助运维人员构建完整的 Windows 软件生命周期管理体系。

## WinGet 基础操作

WinGet 提供了丰富的子命令来管理软件包。下面的脚本展示了最常用的三个操作：搜索软件包、安装软件以及列出已安装的软件。

```powershell
# 搜索软件包
function Find-WinGetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Keyword
    )

    $result = winget search $Keyword --accept-source-agreements 2>&1
    $result
}

# 安装软件包
function Install-WinGetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,

        [switch]$Silent
    )

    $args = @(
        'install'
        '--id', $PackageId
        '--accept-source-agreements'
        '--accept-package-agreements'
    )

    if ($Silent) {
        $args += '--silent'
    }

    Write-Host "正在安装: $PackageId" -ForegroundColor Cyan
    winget @args 2>&1
}

# 列出已安装的软件
function Get-WinGetInstalled {
    $output = winget list --accept-source-agreements 2>&1
    $output
}

# 示例：搜索 VS Code
Find-WinGetPackage -Keyword "Visual Studio Code"

# 示例：安装 VS Code（静默模式）
Install-WinGetPackage -PackageId 'Microsoft.VisualStudioCode' -Silent

# 示例：查看已安装的软件列表
Get-WinGetInstalled
```

执行结果示例：

```
名称                         ID                                版本        来源
---------------------------------------------------------------------------
Visual Studio Code           Microsoft.VisualStudioCode        1.96.2      winget
Visual Studio Code Insiders  Microsoft.VisualStudioCode.Insiders 1.97.0    winget

正在安装: Microsoft.VisualStudioCode
已成功完成安装

名称                   ID                           版本
---------------------------------------------------------------------------
Visual Studio Code     Microsoft.VisualStudioCode   1.96.2
Git for Windows        Git.Git                      2.47.1
PowerShell 7           Microsoft.PowerShell         7.4.6
```

通过上面的函数封装，我们可以将 WinGet 的命令行操作转化为结构化的 PowerShell 函数，便于后续在脚本中组合调用。`--accept-source-agreements` 和 `--accept-package-agreements` 参数可以跳过交互式确认，实现无人值守安装。

## 批量安装与软件清单管理

在企业环境中，我们通常需要根据角色或团队批量安装一组软件。下面的脚本展示了如何通过 JSON 清单文件管理软件列表，并实现一键批量部署。

```powershell
# 定义软件清单（可以保存为外部 JSON 文件）
$softwareList = @(
    @{
        Id       = 'Microsoft.VisualStudioCode'
        Name     = 'Visual Studio Code'
        Category = 'Editor'
    }
    @{
        Id       = 'Git.Git'
        Name     = 'Git for Windows'
        Category = 'VCS'
    }
    @{
        Id       = 'Microsoft.PowerShell'
        Name     = 'PowerShell 7'
        Category = 'Runtime'
    }
    @{
        Id       = 'OpenJS.NodeJS.LTS'
        Name     = 'Node.js LTS'
        Category = 'Runtime'
    }
    @{
        Id       = 'Docker.DockerDesktop'
        Name     = 'Docker Desktop'
        Category = 'Container'
    }
) | ConvertTo-Json -Depth 3

# 将清单保存到文件
$listPath = Join-Path $HOME 'winget-software-list.json'
$softwareList | Out-File -FilePath $listPath -Encoding utf8
Write-Host "软件清单已保存到: $listPath" -ForegroundColor Green

# 从文件加载并批量安装
function Install-WinGetFromList {
    param(
        [Parameter(Mandatory)]
        [string]$ListFile,

        [string[]]$Categories
    )

    $packages = Get-Content $ListFile -Raw | ConvertFrom-Json

    # 按类别过滤
    if ($Categories) {
        $packages = $packages | Where-Object { $_.Category -in $Categories }
    }

    $total = $packages.Count
    $success = 0
    $failed = 0

    foreach ($pkg in $packages) {
        Write-Host "`n[$($success + $failed + 1)/$total] 安装: $($pkg.Name)" -ForegroundColor Cyan

        $output = winget install --id $pkg.Id `
            --accept-source-agreements `
            --accept-package-agreements `
            --silent 2>&1

        $lastLine = ($output | Select-Object -Last 1).ToString()
        if ($lastLine -match '成功|successfully|已安装') {
            Write-Host "  -> 成功" -ForegroundColor Green
            $success++
        } else {
            Write-Host "  -> 失败: $lastLine" -ForegroundColor Red
            $failed++
        }
    }

    # 输出汇总报告
    Write-Host "`n===== 安装汇总 =====" -ForegroundColor Yellow
    Write-Host "总计: $total | 成功: $success | 失败: $failed"
}

# 示例：仅安装 Runtime 类别的软件
Install-WinGetFromList -ListFile $listPath -Categories 'Runtime', 'VCS'
```

执行结果示例：

```
软件清单已保存到: C:\Users\admin\winget-software-list.json

[1/3] 安装: Git for Windows
  -> 成功

[2/3] 安装: PowerShell 7
  -> 成功

[3/3] 安装: Node.js LTS
  -> 成功

===== 安装汇总 =====
总计: 3 | 成功: 3 | 失败: 0
```

使用 JSON 清单文件管理软件列表的好处是：不同团队可以维护各自的清单文件，新员工入职时只需指定对应的清单即可完成环境搭建。同时，清单文件可以纳入 Git 版本管理，便于审计和追溯软件配置变更。

## 软件更新检查与自动化更新

保持软件版本最新是安全运维的基本要求。下面的脚本实现了自动检测可更新的软件，并在确认后执行批量更新，同时支持将更新任务注册为 Windows 计划任务实现定时自动执行。

```powershell
# 检查可更新的软件
function Get-WinGetUpdate {
    $output = winget upgrade --accept-source-agreements 2>&1

    # 解析输出获取可更新的包列表
    $lines = $output -split "`n"
    $updates = @()

    # 找到数据行（跳过标题和分隔线）
    $dataStarted = $false
    foreach ($line in $lines) {
        if ($line -match '^[-\s]+$') {
            $dataStarted = $true
            continue
        }
        if ($dataStarted -and $line.Trim() -and $line -notmatch '^\s*$') {
            $updates += $line.Trim()
        }
    }

    return $updates
}

# 执行更新
function Start-WinGetUpdate {
    param(
        [string]$PackageId,

        [switch]$All,

        [switch]$WhatIf
    )

    if ($All) {
        Write-Host "检查所有可更新的软件..." -ForegroundColor Cyan
        $updates = Get-WinGetUpdate

        if ($updates.Count -eq 0) {
            Write-Host "所有软件均为最新版本" -ForegroundColor Green
            return
        }

        Write-Host "发现 $($updates.Count) 个可更新的软件:`n"
        $updates | ForEach-Object { Write-Host "  - $_" }

        if ($WhatIf) {
            Write-Host "`n[WhatIf 模式] 跳过实际更新" -ForegroundColor Yellow
            return
        }

        $confirm = Read-Host "`n确认更新全部? (Y/N)"
        if ($confirm -eq 'Y') {
            winget upgrade --all `
                --accept-source-agreements `
                --accept-package-agreements 2>&1
        }
    }
    elseif ($PackageId) {
        if ($WhatIf) {
            Write-Host "[WhatIf 模式] 将更新: $PackageId" -ForegroundColor Yellow
            return
        }

        winget upgrade --id $PackageId `
            --accept-source-agreements `
            --accept-package-agreements 2>&1
    }
}

# 定时任务：每天检查更新并记录日志
function Register-WinGetUpdateTask {
    param(
        [string]$Time = '03:00'
    )

    $scriptPath = Join-Path $HOME 'winget-auto-update.ps1'

    # 生成自动更新脚本
    $scriptContent = @"
`$logDir = Join-Path `$HOME 'WinGetUpdateLogs'
if (-not (Test-Path `$logDir)) {
    New-Item -Path `$logDir -ItemType Directory | Out-Null
}

`$logFile = Join-Path `$logDir "update-$(Get-Date -Format 'yyyy-MM-dd').log"
"[$((Get-Date))] 开始检查更新" | Out-File `$logFile -Append

`$output = winget upgrade --all --accept-source-agreements --accept-package-agreements --silent 2>&1
`$output | Out-File `$logFile -Append

"[$((Get-Date))] 更新完成" | Out-File `$logFile -Append
"@

    Set-Content -Path $scriptPath -Value $scriptContent -Encoding utf8

    # 注册计划任务
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' `
        -Argument "-NoProfile -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Daily -At $Time
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries

    Register-ScheduledTask `
        -TaskName 'WinGet-AutoUpdate' `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Force

    Write-Host "已注册每日更新任务，执行时间: $Time" -ForegroundColor Green
}

# 示例：检查更新（仅查看，不执行）
Start-WinGetUpdate -All -WhatIf

# 示例：注册每日凌晨 3 点自动更新任务
# Register-WinGetUpdateTask -Time '03:00'
```

执行结果示例：

```
检查所有可更新的软件...
发现 3 个可更新的软件:

  - Git.Git  2.43.0  2.47.1  winget
  - Microsoft.VisualStudioCode  1.95.0  1.96.2  winget
  - Docker.DockerDesktop  4.34.0  4.35.1  winget

[WhatIf 模式] 跳过实际更新
```

将更新检查注册为 Windows 计划任务后，系统会在每天凌晨自动检查并安装更新，同时将操作日志写入文件。运维人员可以通过查看日志目录下的文件，快速了解每台机器的软件更新情况，确保安全补丁及时到位。

## 注意事项

1. **WinGet 版本要求**：建议使用 WinGet v1.6 或更高版本，旧版本可能不支持 `--accept-package-agreements` 等参数。可以通过 `winget --version` 查看当前版本，通过 Microsoft Store 自动更新 WinGet。

2. **管理员权限**：部分软件的安装需要管理员权限。在脚本中可以使用 `#requires -RunAsAdministrator` 声明，或者以管理员身份运行 PowerShell 来执行安装操作，否则可能会遇到权限不足的错误。

3. **网络环境**：在企业代理环境下，WinGet 可能需要额外配置才能正常访问软件源。可以通过 `winget settings` 命令打开配置文件，设置代理和网络相关参数，或者配置企业内部源（如 Azure Artifacts）作为替代。

4. **安装失败处理**：某些软件不支持静默安装或存在安装依赖冲突。建议在批量部署前先在测试环境中验证清单文件，对于失败的安装记录错误日志并单独处理，避免一个失败阻塞整个部署流程。

5. **计划任务兼容性**：`Register-ScheduledTask` 需要 Windows 8.1 及以上系统。在 Windows Server 环境中，需要确认 Task Scheduler 服务正常运行，且执行账户具有安装软件的权限。对于不支持计划任务的场景，可以考虑使用 Group Policy 的启动脚本替代。

6. **PATH 环境变量刷新**：WinGet 安装完软件后可能修改了系统 PATH，但当前 PowerShell 会话不会自动感知变更。部署完成后需要重启 PowerShell 或手动刷新环境变量：`$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')`，否则后续命令可能找不到新安装的可执行文件。
