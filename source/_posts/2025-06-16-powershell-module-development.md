---
layout: post
date: 2025-06-16 08:00:00
updated: 2025-06-16 08:00:00
title: "PowerShell 技能连载 - 模块开发与打包"
description: PowerTip of the Day - PowerShell Module Development and Packaging
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- module
- development
- packaging
---

_适用于 PowerShell 5.1 及以上版本_

当你发现自己在多个脚本中复制粘贴相同的函数时，就该考虑创建模块了。模块是 PowerShell 代码复用、分发和版本管理的基本单元。一个设计良好的模块不仅方便自己使用，还可以发布到 PowerShell Gallery 供社区使用。本文将讲解从零创建一个完整模块的过程，包括模块清单、函数设计、帮助文档和发布流程。

## 模块结构设计

一个规范的 PowerShell 模块应遵循以下目录结构：

```powershell
# 创建模块骨架
$moduleName = "SystemTools"
$moduleRoot = "C:\Projects\$moduleName"

$directories = @(
    $moduleRoot
    "$moduleRoot\Public"
    "$moduleRoot\Private"
    "$moduleRoot\en-US"
    "$moduleRoot\Tests"
)

foreach ($dir in $directories) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}

# 创建模块入口文件
$moduleFile = @"
# 导入私有函数
`$privateFunctions = Get-ChildItem -Path "`$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach (`$func in `$privateFunctions) {
    . `$func.FullName
}

# 导入公共函数
`$publicFunctions = Get-ChildItem -Path "`$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach (`$func in `$publicFunctions) {
    . `$func.FullName
}

# 导出公共函数
Export-ModuleMember -Function `$publicFunctions.BaseName
"@

Set-Content -Path "$moduleRoot\$moduleName.psm1" -Value $moduleFile
Write-Host "模块骨架已创建：$moduleRoot" -ForegroundColor Green
```

执行结果示例：

```
模块骨架已创建：C:\Projects\SystemTools
```

## 编写模块函数

```powershell
# 公共函数：获取系统信息
$publicFunc = @'
function Get-SystemInfo {
    <#
    .SYNOPSIS
    获取系统基本信息

    .DESCRIPTION
    采集操作系统、CPU、内存和磁盘等系统信息

    .PARAMETER ComputerName
    目标计算机名，默认为本地

    .EXAMPLE
    Get-SystemInfo
    获取本机系统信息

    .EXAMPLE
    Get-SystemInfo -ComputerName SRV01
    获取远程计算机系统信息

    .OUTPUTS
    PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $os = Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName
    $cpu = Get-CimInstance Win32_Processor -ComputerName $ComputerName |
        Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk -ComputerName $ComputerName `
        -Filter "DriveType=3"

    [PSCustomObject]@{
        ComputerName  = $ComputerName
        OS            = $os.Caption
        Version       = $os.Version
        CPU           = $cpu.Name
        CPUCores      = $cpu.NumberOfLogicalProcessors
        TotalRAM_GB   = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        FreeRAM_GB    = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        Disks         = $disk | ForEach-Object {
            [PSCustomObject]@{
                Drive  = $_.DeviceID
                FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                TotalGB = [math]::Round($_.Size / 1GB, 2)
            }
        }
    }
}
'@

Set-Content -Path "$moduleRoot\Public\Get-SystemInfo.ps1" -Value $publicFunc

# 公共函数：测试端口
$testPortFunc = @'
function Test-ServerPort {
    <#
    .SYNOPSIS
    测试远程服务器的 TCP 端口连通性

    .EXAMPLE
    Test-ServerPort -ComputerName web01 -Port 443
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [int]$Port,

        [int]$TimeoutMs = 3000
    )

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $asyncResult = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
    $waited = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

    $isOpen = $false
    if ($waited) {
        try {
            $tcpClient.EndConnect($asyncResult)
            $isOpen = $true
        } catch { $isOpen = $false }
    }

    $tcpClient.Close()

    [PSCustomObject]@{
        ComputerName = $ComputerName
        Port         = $Port
        IsOpen       = $isOpen
    }
}
'@

Set-Content -Path "$moduleRoot\Public\Test-ServerPort.ps1" -Value $testPortFunc
Write-Host "公共函数已创建" -ForegroundColor Green
```

执行结果示例：

```
公共函数已创建
```

## 创建模块清单

模块清单（.psd1）是模块的元数据文件，定义了版本、作者、导出函数等信息：

```powershell
$manifestParams = @{
    Path              = "$moduleRoot\$moduleName.psd1"
    RootModule        = "$moduleName.psm1"
    ModuleVersion     = '1.0.0'
    GUID              = (New-Guid).ToString()
    Author            = 'DevOps Team'
    CompanyName       = 'Contoso'
    Description       = '系统运维工具集 - 提供常用系统管理和诊断函数'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-SystemInfo', 'Test-ServerPort')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    FileList          = @("$moduleName.psm1", "$moduleName.psd1",
                          'Public\Get-SystemInfo.ps1', 'Public\Test-ServerPort.ps1')
    Tags              = @('System', 'Monitoring', 'Diagnostics', 'Tools')
    LicenseUri        = 'https://opensource.org/licenses/MIT'
    ProjectUri        = 'https://github.com/contoso/SystemTools'
    ReleaseNotes      = '初始版本'
}

New-ModuleManifest @manifestParams
Write-Host "模块清单已创建" -ForegroundColor Green

# 验证清单
Test-ModuleManifest -Path "$moduleRoot\$moduleName.psd1"
```

执行结果示例：

```
模块清单已创建

Name          : SystemTools
Path          : C:\Projects\SystemTools\SystemTools.psd1
Description   : 系统运维工具集
ModuleType    : Script
Version       : 1.0.0
ExportedFunctions : {Get-SystemInfo, Test-ServerPort}
```

## 测试与发布

```powershell
# 导入并测试模块
Import-Module "$moduleRoot\$moduleName.psd1" -Force

# 查看导出的命令
Get-Command -Module SystemTools

# 测试函数
Get-SystemInfo

# 发布到 PowerShell Gallery
# Publish-Module -Path $moduleRoot -NuGetApiKey 'your-api-key'

# 也可以打包为 NuGet 包
nuget pack "$moduleRoot\$moduleName.nuspec" -OutputDirectory "C:\Packages"
```

执行结果示例：

```
CommandType  Name            Version Source
-----------  ----            ------- ------
Function     Get-SystemInfo  1.0.0   SystemTools
Function     Test-ServerPort 1.0.0   SystemTools

ComputerName : DESKTOP-WORK01
OS           : Microsoft Windows 11 Pro
Version      : 10.0.22631
CPU          : Intel(R) Core(TM) i7-13700K
CPUCores     : 24
TotalRAM_GB  : 31.89
FreeRAM_GB   : 8.45
```

## 注意事项

1. **函数命名**：遵循 `Verb-Noun` 命名规范，使用 `Get-Verb` 查看批准的动词列表
2. **帮助文档**：每个公共函数都应有基于注释的帮助（`.SYNOPSIS`、`.DESCRIPTION`、`.EXAMPLE`）
3. **CmdletBinding**：所有高级函数都应添加 `[CmdletBinding()]` 属性，支持 `-Verbose`、`-Debug` 等通用参数
4. **版本号规范**：遵循 SemVer（语义化版本号），`Major.Minor.Patch`
5. **私有函数**：内部辅助函数放在 `Private` 目录，不导出给用户使用
6. **兼容性测试**：使用 `PSScriptAnalyzer` 检查代码质量，`Pester` 编写单元测试
