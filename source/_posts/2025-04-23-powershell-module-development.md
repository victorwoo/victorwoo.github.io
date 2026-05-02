---
layout: post
date: 2025-04-23 08:00:00
updated: 2025-04-23 08:00:00
title: "PowerShell 技能连载 - 自定义模块开发与发布"
description: PowerTip of the Day - Custom PowerShell Module Development and Publishing
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- scripting
- best-practices
- package-management
---

_适用于 PowerShell 7.0 及以上版本_

<!-- more -->

## 模块化开发的意义

当你的 PowerShell 脚本从几十行增长到几百行、甚至跨多个文件协作时，把代码组织成模块就变得尤为重要。模块（Module）是 PowerShell 中代码复用和分发的基本单元，它让你可以将相关函数、类、配置打包在一起，通过一条 `Import-Module` 命令即可加载使用。

PowerShell Gallery 是微软官方维护的模块仓库，社区已有超过 4000 个模块可供直接安装。将自己编写的模块发布到 PowerShell Gallery，不仅方便团队成员共享，也能让全球 PowerShell 用户受益。本文将从零开始，带你完成一个自定义模块的开发、测试与发布全流程。

## 规划模块目录结构

一个规范的 PowerShell 模块应当遵循统一的目录结构。模块根目录以模块名命名，内部包含模块清单文件（`.psd1`）、脚本模块文件（`.psm1`）、以及按功能分类的函数文件。此外还应包含测试目录和帮助文档。

下面是一个典型模块的目录结构示例：

```powershell
MyUtils/
├── MyUtils.psd1            # 模块清单
├── MyUtils.psm1            # 模块入口
├── Private/                # 内部函数（不导出）
│   └── _ResolvePath.ps1
├── Public/                 # 公开函数（导出给用户）
│   ├── Get-SystemInfo.ps1
│   └── Send-WebNotification.ps1
├── Tests/                  # Pester 测试
│   └── Get-SystemInfo.Tests.ps1
└── en-US/                  # 帮助文档
    └── About_MyUtils.help.txt
```

这种将 Public 和 Private 函数分离的做法，让模块的公共 API 与内部实现解耦。用户只能调用 Public 目录下的函数，而 Private 目录下的辅助函数对用户不可见，降低了模块的使用复杂度。

## 创建模块清单

模块清单（`.psd1`）是模块的元数据文件，定义了模块的版本、作者、导出命令、依赖关系等信息。PowerShell 提供了 `New-ModuleManifest` cmdlet 来生成这个文件。

以下命令创建一个完整的模块清单：

```powershell
$modulePath = Join-Path $HOME "Documents/PowerShell/Modules/MyUtils"

New-ModuleManifest -Path (Join-Path $modulePath "MyUtils.psd1") `
    -RootModule "MyUtils.psm1" `
    -ModuleVersion "1.0.0" `
    -Author "victorwoo" `
    -Description "日常运维工具函数集" `
    -PowerShellVersion "7.0" `
    -FunctionsToExport @("Get-SystemInfo", "Send-WebNotification") `
    -CmdletsToExport @() `
    -VariablesToExport @() `
    -AliasesToExport @() `
    -PrivateData @{
        PSData = @{
            Tags = @("Utils", "SystemInfo", "Notification")
            ProjectUri = "https://github.com/victorwoo/MyUtils"
            LicenseUri = "https://github.com/victorwoo/MyUtils/blob/main/LICENSE"
            ReleaseNotes = "首个正式版本"
        }
    }
```

执行结果示例：

```
    目录: /Users/victorwoo/Documents/PowerShell/Modules/MyUtils

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         2025/4/23     08:00           2847 MyUtils.psd1
```

清单中 `FunctionsToExport` 显式指定了要导出的函数名。这是一个关键设置——如果省略此参数，PowerShell 会导出模块中所有函数，包括你原本不想公开的内部辅助函数。显式控制导出列表是模块设计的最佳实践。

## 编写模块入口与导出函数

模块入口文件 `.psm1` 负责加载所有函数文件并控制模块的初始化逻辑。一个推荐的写法是使用点 sourcing（dot sourcing）批量加载 Public 和 Private 目录下的脚本。

```powershell
# MyUtils.psm1 - 模块入口文件

# 加载 Private 函数
$privateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Private") `
    -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $privateFiles) {
    . $file.FullName
}

# 加载 Public 函数
$publicFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Public") `
    -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $publicFiles) {
    . $file.FullName
}
```

接下来在 Public 目录下编写一个实用的函数 `Get-SystemInfo`，用于快速获取当前系统的关键信息：

```powershell
# Public/Get-SystemInfo.ps1

function Get-SystemInfo {
    <#
    .SYNOPSIS
    获取当前系统关键运行信息
    .DESCRIPTION
    返回操作系统版本、运行时间、内存使用率和磁盘空间等摘要信息
    .EXAMPLE
    Get-SystemInfo
    #>
    [CmdletBinding()]
    param()

    $os = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $mem = Get-CimInstance Win32_OperatingSystem
    $memPercent = [math]::Round(
        ($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) /
        $mem.TotalVisibleMemorySize * 100, 1
    )

    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $free = [math]::Round($_.FreeSpace / 1GB, 1)
            $total = [math]::Round($_.Size / 1GB, 1)
            [PSCustomObject]@{
                Drive     = $_.DeviceID
                Free_GB   = $free
                Total_GB  = $total
                Used_Pct  = [math]::Round(($total - $free) / $total * 100, 1)
            }
        }

    [PSCustomObject]@{
        OS            = $os
        PowerShell    = $PSVersionTable.PSVersion.ToString()
        Uptime        = $uptime.ToString("dd\.hh\:mm\:ss")
        MemoryUsedPct = $memPercent
        Disks         = $disks
    }
}
```

执行结果示例：

```
OS            : .NET 8.0.2
PowerShell    : 7.4.1
Uptime        : 03.14:22:15
MemoryUsedPct : 68.3
Disks         : {Drive=C:, Free_GB=89.2, Total_GB=256.0, Used_Pct=65.2}

```

函数中使用了 `CimInstance` 而非已弃用的 `WmiObject`，确保在 PowerShell 7 跨平台场景下有更好的兼容性。`[CmdletBinding()]` 属性让普通函数获得高级函数的能力，支持 `-Verbose`、`-Debug` 等通用参数。

## 编写 Pester 测试

模块的质量保障离不开自动化测试。Pester 是 PowerShell 社区最流行的测试框架，几乎所有的社区模块都使用它来编写单元测试。在将模块发布到 PowerShell Gallery 之前，确保测试通过是必要的步骤。

以下是为 `Get-SystemInfo` 编写的 Pester 测试：

```powershell
# Tests/Get-SystemInfo.Tests.ps1

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot ".." "MyUtils.psd1") -Force
}

Describe "Get-SystemInfo" {
    It "返回一个 PSCustomObject" {
        $result = Get-SystemInfo
        $result | Should -BeOfType [PSCustomObject]
    }

    It "包含 OS 属性且类型为字符串" {
        $result = Get-SystemInfo
        $result.OS | Should -BeOfType [string]
        $result.OS.Length | Should -BeGreaterThan 0
    }

    It "包含 PowerShell 版本信息" {
        $result = Get-SystemInfo
        $result.PowerShell | Should -Match "^\d+\.\d+"
    }

    It "内存使用率在 0 到 100 之间" {
        $result = Get-SystemInfo
        $result.MemoryUsedPct | Should -BeGreaterOrEqual 0
        $result.MemoryUsedPct | Should -BeLessOrEqual 100
    }

    It "返回至少一个磁盘信息" {
        $result = Get-SystemInfo
        $result.Disks.Count | Should -BeGreaterOrEqual 1
    }
}
```

执行测试的命令和结果：

```powershell
Invoke-Pester -Path ./Tests -Output Detailed
```

执行结果示例：

```
Starting discovery in 1 files.
Discovery found 5 tests in 12ms.
Running tests.

┌ Tests/Get-SystemInfo.Tests.ps1
│ √ Get-SystemInfo 返回一个 PSCustomObject (8ms)
│ √ Get-SystemInfo 包含 OS 属性且类型为字符串 (3ms)
│ √ Get-SystemInfo 包含 PowerShell 版本信息 (2ms)
│ √ Get-SystemInfo 内存使用率在 0 到 100 之间 (3ms)
│ √ Get-SystemInfo 返回至少一个磁盘信息 (4ms)

Tests passed: 5, Failed: 0, Skipped: 0, NotRun: 0
Total time: 0.23s
```

测试覆盖了函数返回值的类型检查、属性存在性验证、以及数值范围的合理性校验。编写 Pester 测试时，应当关注函数的"契约"——即它承诺返回什么，而非内部实现细节，这样当内部逻辑优化时测试不会轻易失败。

## 发布模块到 PowerShell Gallery

当模块开发和测试都完成后，就可以将其发布到 PowerShell Gallery 供他人使用。发布前需要完成两个准备工作：注册 PowerShell Gallery 账号获取 API Key，以及确保模块清单中的元数据完整准确。

使用 `Publish-Module` 命令即可一键发布：

```powershell
# 首先验证模块清单是否有效
Test-ModuleManifest -Path (Join-Path $modulePath "MyUtils.psd1")

# 发布到 PowerShell Gallery
Publish-Module -Path $modulePath `
    -NuGetApiKey "oy2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" `
    -Repository "PSGallery"
```

执行结果示例：

```
ModuleName      : MyUtils
ModuleVersion   : 1.0.0
Published       : 2025-04-23 08:00:00
PublishedBy     : victorwoo
Repository      : PSGallery
```

发布成功后，任何用户都可以通过以下命令安装和使用你的模块：

```powershell
Install-Module -Name MyUtils -Scope CurrentUser
Import-Module MyUtils
Get-SystemInfo
```

需要注意的是，`Publish-Module` 要求模块清单中的 `PrivateData.PSData` 包含 `Tags`、`ProjectUri` 和 `LicenseUri` 等字段，否则会发布失败。另外，API Key 可以在 [powershellgallery.com](https://www.powershellgallery.com/) 的账户设置页面生成，建议使用作用域限定（scoped）的 Key 而非全权限 Key，以降低安全风险。

## 注意事项

- **显式导出控制**：在 `.psd1` 中使用 `FunctionsToExport` 明确列出要导出的函数名，避免内部函数意外暴露。同时设置 `CmdletsToExport = @()`、`VariablesToExport = @()` 等为空数组，防止默认行为导出不需要的成员。

- **语义化版本号**：模块版本遵循 `Major.Minor.Patch` 规则。破坏性变更升 Major，新增功能升 Minor，Bug 修复升 Patch。PowerShell Gallery 不允许重复上传同一版本号，每次发布必须递增版本号。

- **API Key 安全**：不要将 NuGet API Key 硬编码在脚本中。推荐使用环境变量或 Azure Key Vault 存储，CI/CD 流水线中通过 `$env:NUGET_API_KEY` 传入。

- **跨平台兼容性**：如果你的模块需要在 Linux 和 macOS 上运行，避免使用 `WmiObject`、`Win32_*` 等 Windows 专属类。改用 `CimInstance`、`/proc` 文件系统读取或条件分支处理平台差异。

- **CI/CD 自动化**：在 GitHub Actions 或 Azure Pipelines 中集成 Pester 测试和 `Publish-Module`，实现提交代码后自动测试、打 Tag 后自动发布的工作流，减少人工操作带来的遗漏。
