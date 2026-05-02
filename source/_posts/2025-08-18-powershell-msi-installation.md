---
layout: post
date: 2025-08-18 08:00:00
updated: 2025-08-18 08:00:00
title: "PowerShell 技能连载 - MSI 安装包自动化部署"
description: PowerTip of the Day - MSI Package Automated Deployment in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- msi
- deployment
- automation
- windows-installer
---

_适用于 PowerShell 5.1 及以上版本_

在企业环境中，软件部署是最常见的运维任务之一。MSI（Microsoft Installer）是 Windows 平台上标准的安装包格式，几乎所有企业级软件都提供 MSI 分发方式。手动安装不仅耗时，而且在批量部署场景下几乎不可行。通过 PowerShell 自动化 MSI 安装，可以实现静默安装、参数化配置、日志记录和错误处理，大幅提升部署效率。

随着 DevOps 和基础设施即代码（IaC）理念的普及，将软件安装纳入版本控制的自动化流程已成为标准实践。本文将介绍如何使用 PowerShell 调用 `msiexec.exe` 完成 MSI 包的自动化安装、卸载和状态检测。

<!-- more -->

## 基础：使用 msiexec 进行静默安装

```powershell
# msiexec 是 Windows 自带的 MSI 安装引擎命令行工具
# 常用参数说明：
#   /i        - 安装
#   /x        - 卸载
#   /qn       - 无用户界面（静默）
#   /qb       - 基本界面（仅进度条）
#   /l*v      - 详细日志
#   REBOOT=   - 控制重启行为

$msiPath = 'C:\Packages\example-app-2.0.msi'
$logPath = 'C:\Logs\example-app-install.log'

# 构建安装参数
$arguments = @(
    '/i', $msiPath
    '/qn'
    '/l*v', $logPath
    'REBOOT=ReallySuppress'
    'ALLUSERS=1'
)

# 启动安装进程
$process = Start-Process -FilePath 'msiexec.exe' `
    -ArgumentList $arguments `
    -Wait `
    -PassThru

# 检查返回码
switch ($process.ExitCode) {
    0    { Write-Host '安装成功' -ForegroundColor Green }
    3010 { Write-Host '安装成功，需要重启' -ForegroundColor Yellow }
    1602 { Write-Host '用户取消了安装' -ForegroundColor Yellow }
    1603 { Write-Host '安装过程中发生严重错误' -ForegroundColor Red }
    default { Write-Host "安装返回代码：$_" -ForegroundColor Red }
}
```

执行结果示例：

```text
安装成功
```

## 封装为可复用的安装函数

将安装逻辑封装为函数，方便在批量部署脚本中重复调用。

```powershell
function Install-MSIPackage {
    <#
    .SYNOPSIS
    静默安装 MSI 包
    .PARAMETER Path
    MSI 文件的完整路径
    .PARAMETER LogPath
    安装日志输出路径
    .PARAMETER Properties
    额外的 MSI 属性（键值对）
    .PARAMETER NoRestart
    是否禁止重启
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,

        [string]$LogPath,

        [hashtable]$Properties,

        [switch]$NoRestart
    )

    # 自动生成日志路径
    if (-not $LogPath) {
        $packageName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $logDir = 'C:\Logs\MSI'
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $LogPath = Join-Path $logDir "$packageName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    }

    # 构建参数列表
    $args = @('/i', $Path, '/qn', '/l*v', $LogPath)

    if ($NoRestart) {
        $args += 'REBOOT=ReallySuppress'
    }

    # 附加自定义属性
    if ($Properties) {
        foreach ($key in $Properties.Keys) {
            $args += "$key=$($Properties[$key])"
        }
    }

    Write-Verbose "正在安装：$Path"
    Write-Verbose "日志文件：$LogPath"
    Write-Verbose "参数：$($args -join ' ')"

    $process = Start-Process -FilePath 'msiexec.exe' `
        -ArgumentList $args `
        -Wait `
        -PassThru

    # 构造返回对象
    $result = [PSCustomObject]@{
        MSIPath   = $Path
        LogPath   = $LogPath
        ExitCode  = $process.ExitCode
        Success   = $process.ExitCode -in @(0, 3010)
        Timestamp = Get-Date
    }

    return $result
}
```

调用封装好的函数：

```powershell
$result = Install-MSIPackage -Path 'C:\Packages\vendor-tool-3.5.msi' `
    -Properties @{
        INSTALLDIR = 'C:\Program Files\VendorTool'
        ADD_LOCAL  = 'FeatureMain,FeatureCLI'
    } `
    -NoRestart `
    -Verbose

$result | Format-List
```

执行结果示例：

```text
详细: 正在安装：C:\Packages\vendor-tool-3.5.msi
详细: 日志文件：C:\Logs\MSI\vendor-tool-3.5-20250818-090000.log
详细: 参数：/i C:\Packages\vendor-tool-3.5.msi /qn /l*v C:\Logs\MSI\vendor-tool-3.5-20250818-090000.log REBOOT=ReallySuppress INSTALLDIR=C:\Program Files\VendorTool ADD_LOCAL=FeatureMain,FeatureCLI

MSIPath   : C:\Packages\vendor-tool-3.5.msi
LogPath   : C:\Logs\MSI\vendor-tool-3.5-20250818-090000.log
ExitCode  : 0
Success   : True
Timestamp : 2025/8/18 09:00:15
```

## 检测已安装的 MSI 产品

在安装之前，通常需要先检查目标软件是否已经安装，避免重复部署。Windows 注册表中保存了所有已安装的 MSI 产品信息。

```powershell
function Get-InstalledMSIProduct {
    <#
    .SYNOPSIS
    查询已安装的 MSI 产品列表
    .PARAMETER Name
    按产品名称过滤（支持通配符）
    #>
    [CmdletBinding()]
    param(
        [string]$Name = '*'
    )

    # 从注册表读取已安装产品
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $products = foreach ($path in $uninstallPaths) {
        if (Test-Path $path) {
            Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.PSChildName -and
                    $_.WindowsInstaller -eq 1
                }
        }
    }

    $products |
        Where-Object { $_.DisplayName -like $Name } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSChildName |
        Sort-Object DisplayName
}

# 查找特定产品
Get-InstalledMSIProduct -Name '*7-Zip*' | Format-Table -AutoSize
```

执行结果示例：

```text
DisplayName DisplayVersion Publisher  InstallDate PSChildName
----------- -------------- ---------  ----------- -----------
7-Zip 24.09 24.09          Igor Pavlov 20250115    {23170F69-40C1-2702-2409-000001000000}
```

## 判断是否需要安装

结合版本比较逻辑，判断目标软件是否需要安装或升级。

```powershell
function Test-MSIInstallRequired {
    <#
    .SYNOPSIS
    判断是否需要安装或升级
    .PARAMETER ProductName
    目标产品名称（支持通配符）
    .PARAMETER MinVersion
    要求的最低版本号
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProductName,

        [Version]$MinVersion
    )

    $installed = Get-InstalledMSIProduct -Name $ProductName

    if (-not $installed) {
        Write-Verbose "产品 '$ProductName' 未安装，需要安装"
        return $true
    }

    if ($MinVersion) {
        $currentVersion = [Version]::new(0, 0, 0, 0)
        if ($installed.DisplayVersion) {
            $currentVersion = [Version]$installed.DisplayVersion
        }

        if ($currentVersion -lt $MinVersion) {
            Write-Verbose "当前版本 $currentVersion 低于要求版本 $MinVersion，需要升级"
            return $true
        }

        Write-Verbose "当前版本 $currentVersion 已满足要求版本 $MinVersion，跳过安装"
        return $false
    }

    Write-Verbose "产品 '$ProductName' 已安装，跳过"
    return $false
}

# 示例：检查是否需要安装 7-Zip 24.09 及以上版本
$needInstall = Test-MSIInstallRequired -ProductName '*7-Zip*' -MinVersion '24.9' -Verbose
Write-Host "需要安装: $needInstall"
```

执行结果示例：

```text
详细: 当前版本 24.09 已满足要求版本 24.9，跳过安装
需要安装: False
```

## 批量部署多个 MSI 包

将上述函数组合起来，实现批量自动部署。这在初始化新服务器或统一升级软件时非常有用。

```powershell
# 定义部署清单
$deployList = @(
    @{
        Name       = '*7-Zip*'
        MinVersion = '24.9'
        MSIPath    = '\\fileserver\packages\7z2409-x64.msi'
    }
    @{
        Name       = '*Notepad++*'
        MinVersion = '8.7'
        MSIPath    = '\\fileserver\packages\npp.8.7.Installer.x64.msi'
    }
    @{
        Name       = '*Visual Studio Code*'
        MinVersion = '1.95'
        MSIPath    = '\\fileserver\packages\VSCodeSetup-x64-1.95.0.msi'
    }
)

# 执行批量部署
$results = foreach ($item in $deployList) {
    Write-Host "`n检查：$($item.Name)" -ForegroundColor Cyan

    $needInstall = Test-MSIInstallRequired `
        -ProductName $item.Name `
        -MinVersion $item.MinVersion

    if ($needInstall) {
        Write-Host "开始安装：$($item.MSIPath)" -ForegroundColor Yellow
        $result = Install-MSIPackage -Path $item.MSIPath -NoRestart
        $result | Add-Member -NotePropertyName 'ProductName' -NotePropertyValue $item.Name -PassThru
    } else {
        Write-Host "已满足要求，跳过" -ForegroundColor Green
        [PSCustomObject]@{
            ProductName = $item.Name
            MSIPath     = $item.MSIPath
            Success     = $true
            ExitCode    = -1
            Message     = '已安装且版本满足要求'
        }
    }
}

# 输出部署汇总
Write-Host "`n===== 部署汇总 =====" -ForegroundColor Cyan
$results | Select-Object ProductName, Success, ExitCode | Format-Table -AutoSize
```

执行结果示例：

```text
检查：*7-Zip*
已满足要求，跳过

检查：*Notepad++*
开始安装：\\fileserver\packages\npp.8.7.Installer.x64.msi

检查：*Visual Studio Code*
开始安装：\\fileserver\packages\VSCodeSetup-x64-1.95.0.msi

===== 部署汇总 =====
ProductName            Success ExitCode
-----------            ------- --------
*7-Zip*                    True       -1
*Notepad++*                True        0
*Visual Studio Code*       True        0
```

## MSI 卸载操作

有时需要先卸载旧版本再安装新版本，或者清理不再使用的软件。

```powershell
function Uninstall-MSIPackage {
    <#
    .SYNOPSIS
    静默卸载已安装的 MSI 产品
    .PARAMETER ProductName
    产品名称（支持通配符）
    .PARAMETER LogPath
    卸载日志路径
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProductName,

        [string]$LogPath
    )

    $product = Get-InstalledMSIProduct -Name $ProductName |
        Select-Object -First 1

    if (-not $product) {
        Write-Warning "未找到产品 '$ProductName'"
        return
    }

    # 自动生成日志路径
    if (-not $LogPath) {
        $logDir = 'C:\Logs\MSI'
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $LogPath = Join-Path $logDir "uninstall-$($product.PSChildName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    }

    $args = @(
        '/x', $product.PSChildName
        '/qn'
        '/l*v', $LogPath
        'REBOOT=ReallySuppress'
    )

    Write-Verbose "正在卸载：$($product.DisplayName) $($product.DisplayVersion)"

    $process = Start-Process -FilePath 'msiexec.exe' `
        -ArgumentList $args `
        -Wait `
        -PassThru

    [PSCustomObject]@{
        Product   = $product.DisplayName
        Version   = $product.DisplayVersion
        ExitCode  = $process.ExitCode
        Success   = $process.ExitCode -in @(0, 3010)
        LogPath   = $LogPath
    }
}

# 卸载指定产品
$uninstallResult = Uninstall-MSIPackage -ProductName '*OldTool*' -Verbose
$uninstallResult | Format-List
```

执行结果示例：

```text
详细: 正在卸载：OldTool 1.2.3 1.2.3

Product  : OldTool 1.2.3
Version  : 1.2.3
ExitCode : 0
Success  : True
LogPath  : C:\Logs\MSI\uninstall-{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}-20250818-091500.log
```

## 解析 MSI 安装日志

安装失败时需要分析日志定位问题。以下是自动解析 MSI 日志的关键函数。

```powershell
function Get-MSIInstallError {
    <#
    .SYNOPSIS
    从 MSI 安装日志中提取错误信息
    .PARAMETER LogPath
    MSI 日志文件路径
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$LogPath
    )

    $logContent = Get-Content $LogPath -Encoding UTF8

    # 提取错误行（MSI 日志中错误以 "Return value 3" 标记）
    $errorLines = $logContent |
        Select-String -Pattern 'Return value 3|错误|Error|ERROR' |
        Select-Object -First 20

    # 提取安装属性摘要
    $properties = $logContent |
        Select-String -Pattern '^Property\(S\):' |
        Select-Object -First 10

    # 提取返回码
    $returnCode = $logContent |
        Select-String -Pattern 'Return value [0-9]' |
        Select-Object -Last 1

    [PSCustomObject]@{
        LogFile    = $LogPath
        ReturnCode = if ($returnCode) { ($returnCode.Line -replace '.*Return value (\d+).*', '$1') } else { '未知' }
        Errors     = $errorLines | ForEach-Object { $_.Line }
        Properties = $properties | ForEach-Object { $_.Line }
    }
}

# 分析最近的安装日志
$errorInfo = Get-MSIInstallError -LogPath 'C:\Logs\MSI\vendor-tool-3.5-20250818-090000.log'
$errorInfo | Format-List
```

执行结果示例：

```text
LogFile    : C:\Logs\MSI\vendor-tool-3.5-20250818-090000.log
ReturnCode : 0
Errors     : {}
Properties : {Property(S): ProductCode = {B1C2D3E4-F5A6-7890-BCDE-F12345678901}...}
```

## 注意事项

- **权限要求**：MSI 安装通常需要管理员权限，脚本应以提升模式运行（`#Requires -RunAsAdministrator`）。
- **路径空格**：MSI 文件路径中包含空格时，`msiexec` 可能解析失败，建议使用短路径格式（`Get-Item` 的 `Target` 属性）或确保路径用引号包裹。
- **退出码含义**：`0` 表示成功，`3010` 表示成功但需要重启，`1603` 表示严重错误。应在脚本中对常见退出码做明确处理。
- **日志分析**：生产环境中务必开启 `/l*v` 详细日志，安装失败时日志是排查问题的唯一依据。
- **并发安装**：Windows Installer 不支持同时安装多个 MSI 包（MSI 引擎有全局锁），批量部署时应串行执行，避免并发冲突。
- **版本比较陷阱**：注册表中的 `DisplayVersion` 字段格式不统一（有些是 `1.2.3`，有些是 `1.2.3.4567`），使用 `[Version]` 类型转换时要注意格式兼容性，建议用 `TryParse` 做容错处理。
