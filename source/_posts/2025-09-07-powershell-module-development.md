---
layout: post
date: 2025-09-07 08:00:00
updated: 2025-09-07 08:00:00
title: "PowerShell 技能连载 - 模块开发实战"
description: PowerTip of the Day - Practical Module Development in PowerShell
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
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell 模块是代码复用的标准单元。将常用的函数封装为模块，不仅可以在不同脚本中轻松调用，还能方便地分享给团队成员或发布到 PowerShell Gallery。一个结构良好的模块包含清单文件（PSD1）、脚本模块（PSM1）、帮助文档和测试用例。掌握模块开发，是从"写脚本"到"做工程"的关键一步。

本文将介绍模块的创建、清单配置、打包发布的完整流程。

<!-- more -->

## 创建模块结构

```powershell
# 创建标准模块目录结构
$moduleName = "Utilities"
$moduleRoot = "$env:USERPROFILE\Documents\PowerShell\Modules\$moduleName"
$version = "1.0.0"

$directories = @(
    $moduleRoot
    "$moduleRoot\$version"
    "$moduleRoot\$version\Public"
    "$moduleRoot\$version\Private"
    "$moduleRoot\$version\en-US"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item $dir -ItemType Directory -Force | Out-Null
    }
}

Write-Host "模块目录已创建：$moduleRoot\$version" -ForegroundColor Green

# 创建私有函数
$privateFunction = @'
function Get-InternalConfig {
    [CmdletBinding()]
    param()

    $configPath = Join-Path $env:APPDATA "Utilities\config.json"

    if (Test-Path $configPath) {
        return Get-Content $configPath -Raw | ConvertFrom-Json
    }

    return [PSCustomObject]@{
        LogLevel    = "Info"
        OutputPath  = "$env:TEMP\Utilities"
        MaxRecords  = 1000
    }
}
'@

$privateFunction | Set-Content "$moduleRoot\$version\Private\Get-InternalConfig.ps1"

# 创建公共函数
$publicFunctions = @(
    @{
        Name    = "Get-SystemReport"
        Content = @'
function Get-SystemReport {
    <#
    .SYNOPSIS
    获取系统信息报告
    .DESCRIPTION
    收集操作系统、硬件、网络等系统信息并生成报告对象
    .OUTPUTS
    PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeNetwork,
        [switch]$IncludeServices
    )

    $config = Get-InternalConfig

    $report = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OS           = (Get-CimInstance Win32_OperatingSystem).Caption
        Version      = [System.Environment]::OSVersion.Version.ToString()
        TotalMemoryGB = [math]::Round(
            (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2
        )
        CPU          = (Get-CimInstance Win32_Processor).Name
    }

    if ($IncludeNetwork) {
        $adapters = Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' }
        $report | Add-Member -NotePropertyName Network -NotePropertyValue (
            $adapters | Select-Object InterfaceAlias, IPAddress, PrefixLength
        )
    }

    if ($IncludeServices) {
        $services = Get-Service | Where-Object { $_.Status -eq 'Running' }
        $report | Add-Member -NotePropertyName RunningServices -NotePropertyValue $services.Count
    }

    return $report
}
'@
    }
    @{
        Name    = "Export-SystemReport"
        Content = @'
function Export-SystemReport {
    <#
    .SYNOPSIS
    导出系统报告到文件
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath = "$env:TEMP\SystemReport.json",
        [switch]$IncludeNetwork,
        [switch]$IncludeServices
    )

    $report = Get-SystemReport -IncludeNetwork:$IncludeNetwork -IncludeServices:$IncludeServices
    $report | ConvertTo-Json -Depth 5 | Set-Content $OutputPath -Encoding UTF8
    Write-Host "报告已导出到：$OutputPath" -ForegroundColor Green
    return $OutputPath
}
'@
    }
)

foreach ($func in $publicFunctions) {
    $func.Content | Set-Content "$moduleRoot\$version\Public\$($func.Name).ps1"
}

Write-Host "已创建 $($publicFunctions.Count) 个公共函数" -ForegroundColor Green
```

执行结果示例：

```
模块目录已创建：C:\Users\admin\Documents\PowerShell\Modules\Utilities\1.0.0
已创建 2 个公共函数
```

## 模块清单与入口

```powershell
# 创建 PSM1 入口文件（加载所有函数）
$psm1Content = @'
# 加载私有函数
$private = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $private) {
    . $file.FullName
}

# 加载公共函数
$public = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $public) {
    . $file.FullName
}

# 导出公共函数
Export-ModuleMember -Function $public.BaseName
'@

$psm1Content | Set-Content "$moduleRoot\$version\Utilities.psm1"

# 创建 PSD1 模块清单
$manifestParams = @{
    Path              = "$moduleRoot\$version\Utilities.psd1"
    RootModule        = "Utilities.psm1"
    ModuleVersion     = $version
    Author            = "Admin"
    CompanyName       = "IT Department"
    Description       = "日常运维工具集"
    PowerShellVersion = "5.1"
    FunctionsToExport = @("Get-SystemReport", "Export-SystemReport")
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    FileList          = @("Utilities.psm1", "Utilities.psd1",
                          "Public\Get-SystemReport.ps1",
                          "Public\Export-SystemReport.ps1",
                          "Private\Get-InternalConfig.ps1")
    PrivateData       = @{
        PSData = @{
            Tags       = @("Utilities", "SystemReport", "Admin")
            LicenseUri = "https://opensource.org/licenses/MIT"
            ProjectUri = "https://github.com/example/Utilities"
        }
    }
}

New-ModuleManifest @manifestParams
Write-Host "模块清单已创建" -ForegroundColor Green

# 验证模块
Test-ModuleManifest "$moduleRoot\$version\Utilities.psd1" |
    Select-Object Name, Version, Author, Description, ExportedFunctions |
    Format-List

# 导入并测试
Import-Module Utilities -Force
Get-Command -Module Utilities | Format-Table Name, CommandType -AutoSize
```

执行结果示例：

```
模块清单已创建

Name             : Utilities
Version          : 1.0.0
Author           : Admin
Description      : 日常运维工具集
ExportedFunctions : {[Get-SystemReport, Export-SystemReport]}

Name               CommandType
----               -----------
Get-SystemReport   Function
Export-SystemReport Function
```

## 模块发布与版本管理

```powershell
# 语义化版本管理
function Update-ModuleVersion {
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [ValidateSet("Major", "Minor", "Patch")]
        [string]$Bump = "Patch"
    )

    $manifest = Test-ModuleManifest $ManifestPath
    $current = [version]$manifest.Version

    $newVersion = switch ($Bump) {
        "Major" { [version]::new($current.Major + 1, 0, 0) }
        "Minor" { [version]::new($current.Major, $current.Minor + 1, 0) }
        "Patch" { [version]::new($current.Major, $current.Minor, $current.Build + 1) }
    }

    # 更新清单中的版本号
    $content = Get-Content $ManifestPath -Raw
    $content = $content -replace "ModuleVersion = '\d+\.\d+\.\d+'", "ModuleVersion = '$newVersion'"
    $content | Set-Content $ManifestPath -Encoding UTF8

    Write-Host "版本已更新：$current -> $newVersion" -ForegroundColor Green
    return $newVersion
}

# 升级补丁版本
Update-ModuleVersion -ManifestPath "$moduleRoot\$version\Utilities.psd1" -Bump Patch

# 创建 NuGet 包（用于内部分发）
function Publish-ModuleToLocalRepo {
    param(
        [string]$ModulePath,
        [string]$RepositoryPath = "\\fileserver\PSRepository"
    )

    if (-not (Test-Path $RepositoryPath)) {
        New-Item $RepositoryPath -ItemType Directory -Force | Out-Null
    }

    # 注册本地仓库
    if (-not (Get-PSRepository -Name "LocalRepo" -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Name "LocalRepo" `
            -SourceLocation $RepositoryPath `
            -PublishLocation $RepositoryPath `
            -InstallationPolicy Trusted
    }

    Publish-Module -Path $ModulePath -Repository "LocalRepo"
    Write-Host "模块已发布到本地仓库：$RepositoryPath" -ForegroundColor Green
}

# Publish-ModuleToLocalRepo -ModulePath "$moduleRoot\$version"

# 模块依赖管理
$dependencyCheck = {
    $module = "Utilities"
    $installed = Get-Module -ListAvailable -Name $module |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($installed) {
        Write-Host "$module 版本：$($installed.Version)" -ForegroundColor Green

        # 检查依赖模块
        $manifest = Test-ModuleManifest $installed.Path
        if ($manifest.RequiredModules) {
            foreach ($req in $manifest.RequiredModules) {
                $reqInstalled = Get-Module -ListAvailable -Name $req.Name
                if (-not $reqInstalled) {
                    Write-Host "缺少依赖：$($req.Name)" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "未安装模块：$module" -ForegroundColor Yellow
    }
}

& $dependencyCheck
```

执行结果示例：

```
版本已更新：1.0.0 -> 1.0.1
Utilities 版本：1.0.1
```

## 注意事项

1. **命名规范**：模块名使用 PascalCase，函数名使用 Verb-Noun 格式，动词从 `Get-Verb` 的批准列表中选取
2. **清单文件**：PSD1 是模块的元数据入口，`FunctionsToExport` 应显式列出而非使用通配符，提升加载性能
3. **帮助文档**：使用基于注释的帮助（`.SYNOPSIS`、`.DESCRIPTION`）或外部 MAML 帮助文件，`Get-Help` 才能正常显示
4. **兼容性**：注意区分 PowerShell 5.1 和 7.x 的差异，模块清单的 `PowerShellVersion` 应如实标注最低要求
5. **测试**：使用 Pester 框架为公共函数编写单元测试，确保模块升级不破坏现有功能
6. **发布**：发布到 PowerShell Gallery 前使用 `Test-ModuleManifest` 和 `Test-ScriptFileInfo` 验证元数据完整性
