---
layout: post
date: 2025-04-29 08:00:00
updated: 2025-04-29 08:00:00
title: "PowerShell 技能连载 - WinGet 包管理自动化"
description: PowerTip of the Day - Automating Package Management with WinGet and PowerShell
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
- automation
- windows
---

_适用于 Windows 10/11，PowerShell 7.0 及以上版本_

<!-- more -->

## WinGet：Windows 包管理的新时代

在 Linux 世界中，`apt`、`yum`、`pacman` 等包管理器早已是系统管理的标配工具。而在 Windows 平台上，长期以来我们只能依赖图形界面的安装向导，或者各自为政的第三方管理工具（如 Chocolatey、Scoop）。2020 年微软推出 WinGet（Windows Package Manager）后，这一局面终于开始改变。

如今 WinGet 已经相当成熟，软件源中收录了超过 6000 款常用软件，覆盖开发工具、浏览器、办公套件等几乎所有类别。更重要的是，WinGet 是 Windows 10/11 的内置组件，无需额外安装即可使用。将 WinGet 与 PowerShell 结合，我们可以实现软件安装、升级、卸载的完全自动化——无论是日常维护还是新机初始化，都能一键搞定。

本文将介绍如何用 PowerShell 封装 WinGet 命令、批量安装软件清单、自动检测升级、生成软件报告，以及编写新机初始化脚本。

## 封装 WinGet 常用命令

WinGet 的命令行输出是纯文本格式，不便于在脚本中进一步处理。我们先将常用的 WinGet 操作封装成 PowerShell 函数，输出结构化对象，方便后续链式调用和自动化编排。

```powershell
function Get-WinGetPackage {
    <#
    .SYNOPSIS
    获取已安装的 WinGet 软件包列表
    #>
    [CmdletBinding()]
    param(
        [string]$Name
    )
    $args = @('list')
    if ($Name) {
        $args += @('--name', $Name)
    }
    $output = winget @args 2>&1
    # 跳过表头和末尾的摘要行
    $lines = $output | Where-Object {
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\s*$' -and
        $_ -notmatch '^\d+ packages'
    }
    foreach ($line in $lines) {
        $parts = $line -split '\s{2,}'
        if ($parts.Count -ge 3) {
            [PSCustomObject]@{
                Name    = $parts[0]
                Id      = $parts[1]
                Version = $parts[2]
            }
        }
    }
}

function Install-WinGetPackage {
    <#
    .SYNOPSIS
    安装 WinGet 软件包
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Id,
        [switch]$Force
    )
    if ($PSCmdlet.ShouldProcess($Id, 'Install WinGet package')) {
        $installArgs = @('install', '--id', $Id, '--accept-package-agreements',
            '--accept-source-agreements')
        if ($Force) {
            $installArgs += '--force'
        }
        winget @installArgs 2>&1
    }
}

function Update-WinGetPackage {
    <#
    .SYNOPSIS
    升级指定的 WinGet 软件包
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Id,
        [switch]$All
    )
    if ($PSCmdlet.ShouldProcess($Id, 'Update WinGet package')) {
        $upgradeArgs = @('upgrade')
        if ($All) {
            $upgradeArgs += '--all'
        } elseif ($Id) {
            $upgradeArgs += @('--id', $Id)
        }
        $upgradeArgs += @('--accept-package-agreements', '--accept-source-agreements')
        winget @upgradeArgs 2>&1
    }
}
```

上面的代码定义了三个核心函数：`Get-WinGetPackage` 解析 `winget list` 的纯文本输出为结构化对象，`Install-WinGetPackage` 封装安装命令并自动接受协议，`Update-WinGetPackage` 封装升级命令。每个函数都支持 `ShouldProcess`，可以通过 `-WhatIf` 参数进行干运行预览。

```text
Name                Id                             Version
----                --                             -------
PowerShell          Microsoft.PowerShell           7.4.6
Visual Studio Code  Microsoft.VisualStudioCode     1.96.2
Windows Terminal    Microsoft.WindowsTerminal       1.21.3231
Git                 Git.Git                        2.47.1
7-Zip               7zip.7zip                      24.08
```

## 批量安装软件清单

重装系统后手动安装几十个软件是一件耗时且容易遗漏的事情。将常用软件整理成 JSON 清单文件，然后用脚本批量安装，可以确保每次安装的软件集一致且不遗漏。

首先，创建一个软件清单 JSON 文件，将需要的软件按类别分组：

```powershell
# 定义软件安装清单
$manifest = @'
{
  "categories": [
    {
      "name": "开发工具",
      "packages": [
        "Microsoft.VisualStudioCode",
        "Git.Git",
        "Microsoft.PowerShell",
        "OpenJS.NodeJS.LTS",
        "Python.Python.3.12"
      ]
    },
    {
      "name": "浏览器",
      "packages": [
        "Google.Chrome",
        "Mozilla.Firefox"
      ]
    },
    {
      "name": "系统工具",
      "packages": [
        "7zip.7zip",
        "Microsoft.WindowsTerminal",
        "Microsoft.Powertoys",
        "voidtools.Everything"
      ]
    },
    {
      "name": "效率工具",
      "packages": [
        "Obsidian.Obsidian",
        "Telegram.TelegramDesktop"
      ]
    }
  ]
}
'@

$pkgList = $manifest | ConvertFrom-Json

foreach ($category in $pkgList.categories) {
    Write-Host "`n=== 安装类别: $($category.name) ===" -ForegroundColor Cyan
    foreach ($pkgId in $category.packages) {
        Write-Host "正在安装: $pkgId ..." -ForegroundColor Yellow -NoNewline
        $result = winget install --id $pkgId `
            --accept-package-agreements `
            --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " 完成" -ForegroundColor Green
        } else {
            Write-Host " 失败 (退出码: $LASTEXITCODE)" -ForegroundColor Red
            Write-Host "  错误信息: $($result | Select-Object -Last 2)" -ForegroundColor DarkRed
        }
    }
}
```

这段代码将软件清单以 JSON 格式定义，按类别分组管理。安装时逐类别遍历，每个软件包单独安装并报告结果。JSON 格式的清单文件也可以单独保存到磁盘，纳入版本控制，方便团队共享。

```text
=== 安装类别: 开发工具 ===
正在安装: Microsoft.VisualStudioCode ... 完成
正在安装: Git.Git ... 完成
正在安装: Microsoft.PowerShell ... 完成
正在安装: OpenJS.NodeJS.LTS ... 完成
正在安装: Python.Python.3.12 ... 完成

=== 安装类别: 浏览器 ===
正在安装: Google.Chrome ... 完成
正在安装: Mozilla.Firefox ... 完成

=== 安装类别: 系统工具 ===
正在安装: 7zip.7zip ... 完成
正在安装: Microsoft.WindowsTerminal ... 完成
正在安装: Microsoft.Powertoys ... 完成
正在安装: voidtools.Everything ... 完成

=== 安装类别: 效率工具 ===
正在安装: Obsidian.Obsidian ... 完成
正在安装: Telegram.TelegramDesktop ... 完成
```

## 检测已安装软件并自动升级

软件更新往往包含安全补丁和功能改进，但手动逐个检查升级非常繁琐。下面的脚本会扫描所有可通过 WinGet 升级的软件，筛选出有可用更新的，然后自动执行升级。

```powershell
function Invoke-WinGetAutoUpgrade {
    <#
    .SYNOPSIS
    检测所有可升级的 WinGet 软件包并执行升级
    .PARAMETER DryRun
    仅显示可升级的软件，不实际执行升级
    .PARAMETER ExcludeIds
    排除不需要升级的软件包 ID 列表
    #>
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [string[]]$ExcludeIds
    )
    Write-Host "正在扫描可升级的软件包..." -ForegroundColor Cyan
    $upgradeList = winget upgrade 2>&1
    $packages = $upgradeList | Where-Object {
        $_ -match '^\S' -and
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\d+ upgrades'
    } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 4) {
            [PSCustomObject]@{
                Name          = $parts[0]
                Id            = $parts[1]
                InstalledVer  = $parts[2]
                AvailableVer  = $parts[3]
            }
        }
    }
    if ($ExcludeIds) {
        $packages = $packages | Where-Object { $_.Id -notin $ExcludeIds }
    }
    if (-not $packages) {
        Write-Host "所有软件均为最新版本" -ForegroundColor Green
        return
    }
    Write-Host "发现 $($packages.Count) 个可升级软件包:" -ForegroundColor Yellow
    $packages | Format-Table -Property Name, Id, InstalledVer, AvailableVer -AutoSize
    if ($DryRun) {
        Write-Host "[DryRun] 跳过实际升级" -ForegroundColor DarkYellow
        return
    }
    foreach ($pkg in $packages) {
        Write-Host "升级 $($pkg.Name) ($($pkg.InstalledVer) -> $($pkg.AvailableVer))..." `
            -ForegroundColor Yellow -NoNewline
        $result = winget upgrade --id $pkg.Id `
            --accept-package-agreements `
            --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " 完成" -ForegroundColor Green
        } else {
            Write-Host " 失败" -ForegroundColor Red
        }
    }
    Write-Host "`n升级完成" -ForegroundColor Green
}

# 示例：排除已知不兼容升级的软件，先干运行查看
Invoke-WinGetAutoUpgrade -DryRun -ExcludeIds @('SomeApp.Legacy')

# 确认后执行实际升级
# Invoke-WinGetAutoUpgrade -ExcludeIds @('SomeApp.Legacy')
```

这个函数支持 `-DryRun` 参数先预览可升级列表而不实际执行，也支持 `-ExcludeIds` 排除某些已知升级后会出问题的软件。对于生产环境，建议先运行干运行模式确认，再执行实际升级。

```text
正在扫描可升级的软件包...
发现 4 个可升级软件包:

Name                Id                          InstalledVer AvailableVer
----                --                          ------------ ------------
7-Zip               7zip.7zip                   24.06        24.08
Visual Studio Code  Microsoft.VisualStudioCode  1.95.3       1.96.2
Git                 Git.Git                     2.46.0       2.47.1
PowerShell          Microsoft.PowerShell        7.4.5        7.4.6

升级 7-Zip (24.06 -> 24.08)... 完成
升级 Visual Studio Code (1.95.3 -> 1.96.2)... 完成
升级 Git (2.46.0 -> 2.47.1)... 完成
升级 PowerShell (7.4.5 -> 7.4.6)... 完成

升级完成
```

## 生成软件清单报告

定期生成系统已安装软件的报告，有助于审计和资产盘点。下面的脚本将 WinGet 管理的软件信息导出为 CSV 和 HTML 两种格式，便于存档和查看。

```powershell
function Export-WinGetReport {
    <#
    .SYNOPSIS
    生成已安装软件清单报告，输出 CSV 和 HTML 格式
    .PARAMETER OutputDir
    报告输出目录，默认为当前用户的桌面
    #>
    [CmdletBinding()]
    param(
        [string]$OutputDir = [Environment]::GetFolderPath('Desktop')
    )
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $csvPath = Join-Path $OutputDir "WinGet_Inventory_${timestamp}.csv"
    $htmlPath = Join-Path $OutputDir "WinGet_Inventory_${timestamp}.html"
    Write-Host "正在收集已安装软件信息..." -ForegroundColor Cyan
    $rawOutput = winget list 2>&1
    $packages = $rawOutput | Where-Object {
        $_ -match '^\S' -and
        $_ -notmatch '^Name\s+Id' -and
        $_ -notmatch '^\d+ packages'
    } | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 3) {
            [PSCustomObject]@{
                Name      = $parts[0]
                Id        = $parts[1]
                Version   = $parts[2]
                ScanDate  = (Get-Date -Format 'yyyy-MM-dd')
            }
        }
    }
    # 导出 CSV
    $packages | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "CSV 报告已保存: $csvPath" -ForegroundColor Green
    # 导出 HTML
    $htmlHeader = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>WinGet 软件清单报告 - $timestamp</title>
<style>
body { font-family: 'Segoe UI', sans-serif; margin: 20px; }
h1 { color: #0078d4; }
table { border-collapse: collapse; width: 100%; }
th { background: #0078d4; color: white; padding: 8px 12px; text-align: left; }
td { border-bottom: 1px solid #e0e0e0; padding: 8px 12px; }
tr:nth-child(even) { background: #f5f5f5; }
.total { margin-top: 16px; font-weight: bold; color: #333; }
</style>
</head>
<body>
<h1>WinGet 软件清单报告</h1>
<p>生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
"@
    $htmlBody = $packages | ConvertTo-Html -Fragment
    $htmlFooter = @"
<p class="total">共 $($packages.Count) 个软件包</p>
</body></html>
"@
    $htmlHeader + $htmlBody + $htmlFooter | Set-Content -Path $htmlPath -Encoding UTF8
    Write-Host "HTML 报告已保存: $htmlPath" -ForegroundColor Green
    Write-Host "共发现 $($packages.Count) 个已安装软件包" -ForegroundColor Cyan
}

Export-WinGetReport
```

脚本会同时输出 CSV 和 HTML 两种格式。CSV 适合导入 Excel 进行进一步分析，HTML 报告则可以直接在浏览器中查看，样式更友好。两种文件都以时间戳命名，方便归档对比。

```text
正在收集已安装软件信息...
CSV 报告已保存: C:\Users\admin\Desktop\WinGet_Inventory_20250429_080000.csv
HTML 报告已保存: C:\Users\admin\Desktop\WinGet_Inventory_20250429_080000.html
共发现 42 个已安装软件包
```

## 新机初始化脚本

将前面的功能组合起来，我们可以编写一个完整的新机初始化脚本。这个脚本会安装基础软件、配置 PowerShell 环境、生成初始软件报告，让一台全新的 Windows 电脑在几分钟内进入可工作状态。

```powershell
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 新机初始化脚本
.DESCRIPTION
    通过 WinGet 批量安装常用软件，配置 PowerShell 环境，
    生成软件清单报告，快速搭建工作环境。
.NOTES
    需要以管理员权限运行
#>
param(
    [string]$ManifestPath,
    [switch]$SkipUpgrade,
    [switch]$SkipReport
)
$ErrorActionPreference = 'Stop'
Write-Host @"

============================================
  Windows 新机初始化脚本
  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
============================================

"@ -ForegroundColor Cyan
# 步骤 1: 确认 WinGet 可用
Write-Host "[1/5] 检查 WinGet 可用性..." -ForegroundColor Yellow
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCmd) {
    Write-Host "WinGet 未安装，正在通过 App Installer 安装..." -ForegroundColor Yellow
    # Windows 11 通常自带，Windows 10 可能需要从 Microsoft Store 安装
    Write-Host "请从 Microsoft Store 安装 '应用安装程序' 后重试" -ForegroundColor Red
    return
}
Write-Host "WinGet 版本: $(winget --version)" -ForegroundColor Green
# 步骤 2: 加载软件清单
Write-Host "`n[2/5] 加载软件安装清单..." -ForegroundColor Yellow
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $PSScriptRoot 'software-manifest.json'
}
if (-not (Test-Path $ManifestPath)) {
    Write-Host "清单文件不存在: $ManifestPath" -ForegroundColor Red
    Write-Host "请创建清单文件或通过 -ManifestPath 参数指定路径" -ForegroundColor Yellow
    return
}
$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$totalPkgs = ($manifest.categories | ForEach-Object { $_.packages.Count } |
    Measure-Object -Sum).Sum
Write-Host "清单包含 $($manifest.categories.Count) 个类别，共 $totalPkgs 个软件包" `
    -ForegroundColor Green
# 步骤 3: 批量安装
Write-Host "`n[3/5] 开始批量安装..." -ForegroundColor Yellow
$success = 0
$failed = 0
foreach ($category in $manifest.categories) {
    Write-Host "`n--- $($category.name) ---" -ForegroundColor Cyan
    foreach ($pkgId in $category.packages) {
        try {
            winget install --id $pkgId `
                --accept-package-agreements `
                --accept-source-agreements 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] $pkgId" -ForegroundColor Green
                $success++
            } else {
                Write-Host "  [FAIL] $pkgId (退出码: $LASTEXITCODE)" -ForegroundColor Red
                $failed++
            }
        } catch {
            Write-Host "  [ERROR] $pkgId : $_" -ForegroundColor Red
            $failed++
        }
    }
}
Write-Host "`n安装统计: 成功 $success / 失败 $failed / 总计 $totalPkgs" -ForegroundColor Cyan
# 步骤 4: 升级已安装软件
if (-not $SkipUpgrade) {
    Write-Host "`n[4/5] 升级所有已安装软件到最新版..." -ForegroundColor Yellow
    winget upgrade --all --accept-package-agreements --accept-source-agreements 2>&1
    Write-Host "升级完成" -ForegroundColor Green
} else {
    Write-Host "`n[4/5] 跳过软件升级" -ForegroundColor DarkYellow
}
# 步骤 5: 生成报告
if (-not $SkipReport) {
    Write-Host "`n[5/5] 生成软件清单报告..." -ForegroundColor Yellow
    Export-WinGetReport
} else {
    Write-Host "`n[5/5] 跳过报告生成" -ForegroundColor DarkYellow
}
Write-Host @"

============================================
  初始化完成！
  成功安装: $success
  安装失败: $failed
  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
============================================

"@ -ForegroundColor Green
```

这个脚本设计了五个步骤：检查 WinGet 可用性、加载软件清单、批量安装、升级已安装软件、生成报告。每一步都有清晰的进度提示，支持通过参数跳过升级和报告步骤。脚本开头使用 `#Requires -RunAsAdministrator` 确保以管理员权限运行，因为部分软件安装需要提升权限。

```text
============================================
  Windows 新机初始化脚本
  2025-04-29 08:00:00
============================================

[1/5] 检查 WinGet 可用性...
WinGet 版本: v1.9.25200

[2/5] 加载软件安装清单...
清单包含 4 个类别，共 13 个软件包

[3/5] 开始批量安装...

--- 开发工具 ---
  [OK] Microsoft.VisualStudioCode
  [OK] Git.Git
  [OK] Microsoft.PowerShell
  [OK] OpenJS.NodeJS.LTS
  [OK] Python.Python.3.12

--- 浏览器 ---
  [OK] Google.Chrome
  [OK] Mozilla.Firefox

--- 系统工具 ---
  [OK] 7zip.7zip
  [OK] Microsoft.WindowsTerminal
  [OK] Microsoft.Powertoys
  [OK] voidtools.Everything

--- 效率工具 ---
  [OK] Obsidian.Obsidian
  [OK] Telegram.TelegramDesktop

安装统计: 成功 13 / 失败 0 / 总计 13

[4/5] 升级所有已安装软件到最新版...
升级完成

[5/5] 生成软件清单报告...
CSV 报告已保存: C:\Users\admin\Desktop\WinGet_Inventory_20250429_080000.csv
HTML 报告已保存: C:\Users\admin\Desktop\WinGet_Inventory_20250429_080000.html
共发现 42 个已安装软件包

============================================
  初始化完成！
  成功安装: 13
  安装失败: 0
  2025-04-29 08:05:32
============================================
```

## 注意事项

- **管理员权限**：部分软件（如系统级安装的程序）需要以管理员身份运行 PowerShell，脚本中已通过 `#Requires -RunAsAdministrator` 确保这一点
- **WinGet 输出解析**：WinGet 的命令行输出格式可能在版本更新后变化，解析逻辑需要相应调整。如果遇到解析异常，建议检查 WinGet 版本并更新解析正则
- **软件源一致性**：WinGet 有两个源（winget 和 msstore），某些软件同时存在于两个源中，安装时建议使用 `--id` 精确指定软件包 ID，避免歧义
- **安装顺序**：部分软件有依赖关系（如 VS Code 扩展依赖 VS Code 本体），清单中应确保依赖项排在前面
- **网络环境**：在企业网络中，可能需要配置代理或使用内部软件源，WinGet 支持通过 `--source` 参数指定自定义源
- **错误处理**：批量安装时某个软件失败不应阻断整个流程，脚本中对每个软件单独 try/catch 处理，最终汇总成功和失败数量
