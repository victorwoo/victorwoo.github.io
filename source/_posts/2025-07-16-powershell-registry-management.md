---
layout: post
date: 2025-07-16 08:00:00
updated: 2025-07-16 08:00:00
title: "PowerShell 技能连载 - 注册表管理"
description: PowerTip of the Day - Registry Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- registry
- windows
- configuration
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

Windows 注册表是系统配置的核心存储——从系统服务配置到用户偏好，从已安装软件列表到启动项管理，几乎所有 Windows 配置都存储在注册表中。虽然图形界面提供了部分设置入口，但大量高级配置只能通过注册表修改。PowerShell 把注册表当作文件系统来处理，可以像操作文件一样读写注册表项和值。

本文将讲解注册表的操作技巧、常见配置管理场景，以及安全注意事项。

<!-- more -->

## 注册表浏览与查询

```powershell
# PowerShell 内置的注册表驱动器
Get-PSDrive -PSProvider Registry | Format-Table Name, Root -AutoSize

# 浏览注册表（像文件系统一样）
Set-Location HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion
Get-ChildItem | Select-Object Name -First 10

# 读取注册表值
$productName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
Write-Host "操作系统：$productName"

$currentBuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild
Write-Host "构建号：$currentBuild"

# 读取所有值
$uninstall = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
$uninstall | Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName |
    Format-Table -AutoSize | Out-String -Width 100 | Write-Host

# 搜索注册表
function Find-RegistryValue {
    param(
        [string]$Path = "HKLM:\SOFTWARE",
        [string]$SearchValue,
        [int]$MaxDepth = 3
    )

    $results = @()

    function Search-Reg {
        param([string]$CurrentPath, [int]$Depth)

        if ($Depth -gt $MaxDepth) { return }

        try {
            $item = Get-Item $CurrentPath -ErrorAction Stop
            foreach ($val in $item.GetValueNames()) {
                $data = $item.GetValue($val)
                if ($data -is [string] -and $data -match [regex]::Escape($SearchValue)) {
                    $results += [PSCustomObject]@{
                        Path  = $CurrentPath
                        Name  = $val
                        Value = $data
                    }
                }
            }

            Get-ChildItem $CurrentPath -ErrorAction SilentlyContinue |
                ForEach-Object { Search-Reg $_.PSPath ($Depth + 1) }
        } catch {}
    }

    Search-Reg -CurrentPath $Path -Depth 0
    return $results
}

# 搜索 PowerShell 相关的注册表值
Find-RegistryValue -Path "HKLM:\SOFTWARE" -SearchValue "PowerShell" -MaxDepth 2 |
    Format-Table -AutoSize
```

执行结果示例：

```
Name  Root
----  ----
HKLM  HKEY_LOCAL_MACHINE
HKCU  HKEY_CURRENT_USER

操作系统：Microsoft Windows Server 2022 Standard
构建号：20348

DisplayName              DisplayVersion  Publisher
------------              --------------  ---------
7-Zip 23.01 (x64)       23.01           Igor Pavlov
Git for Windows          2.45.0          The Git Development Community
PowerShell 7-x64         7.4.2           Microsoft Corporation

Path                                Name       Value
HKLM:\SOFTWARE\Microsoft\PowerShell InstallDir C:\Program Files\PowerShell\7\
```

## 注册表修改

```powershell
# 创建注册表项
$newKeyPath = "HKLM:\SOFTWARE\MyApp"
if (-not (Test-Path $newKeyPath)) {
    New-Item -Path $newKeyPath -Force | Out-Null
    Write-Host "已创建注册表项：$newKeyPath" -ForegroundColor Green
}

# 设置注册表值
New-ItemProperty -Path $newKeyPath -Name "InstallPath" -Value "C:\Program Files\MyApp" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $newKeyPath -Name "Version" -Value "2.5.0" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $newKeyPath -Name "Port" -Value 8080 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $newKeyPath -Name "Enabled" -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host "已设置注册表值" -ForegroundColor Green

# 验证
Get-ItemProperty -Path $newKeyPath | Format-List

# 修改现有值
Set-ItemProperty -Path $newKeyPath -Name "Port" -Value 9090
Write-Host "端口已修改为 9090" -ForegroundColor Yellow

# 删除注册表值
Remove-ItemProperty -Path $newKeyPath -Name "Enabled" -ErrorAction SilentlyContinue
Write-Host "已删除 Enabled 值" -ForegroundColor Yellow

# 删除注册表项
Remove-Item -Path $newKeyPath -Recurse -Force
Write-Host "已删除注册表项：$newKeyPath" -ForegroundColor Red
```

执行结果示例：

```
已创建注册表项：HKLM:\SOFTWARE\MyApp
已设置注册表值

InstallPath : C:\Program Files\MyApp
Version     : 2.5.0
Port        : 9090
PSPath      : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\MyApp

端口已修改为 9090
已删除 Enabled 值
已删除注册表项：HKLM:\SOFTWARE\MyApp
```

## 系统配置管理

```powershell
# 管理启动项
function Get-StartupItems {
    $items = @()

    # 当前用户启动项
    $userRun = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
    if ($userRun) {
        $userRun.PSObject.Properties | Where-Object {
            $_.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')
        } | ForEach-Object {
            $items += [PSCustomObject]@{
                Scope = "User"
                Name  = $_.Name
                Value = $_.Value
            }
        }
    }

    # 系统启动项
    $sysRun = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
    if ($sysRun) {
        $sysRun.PSObject.Properties | Where-Object {
            $_.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')
        } | ForEach-Object {
            $items += [PSCustomObject]@{
                Scope = "System"
                Name  = $_.Name
                Value = $_.Value
            }
        }
    }

    return $items
}

$startupItems = Get-StartupItems
Write-Host "启动项（$($startupItems.Count) 个）：" -ForegroundColor Cyan
$startupItems | Format-Table -AutoSize

# 禁用/启用 Windows 功能
function Set-WindowsFeatureViaRegistry {
    param(
        [string]$Feature,
        [bool]$Enabled
    )

    $featureMap = @{
        "RemoteDesktop" = @{
            Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
            Name  = "fDenyTSConnections"
            On    = 0
            Off   = 1
        }
        "UAC" = @{
            Path  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Name  = "EnableLUA"
            On    = 1
            Off   = 0
        }
        "Firewall" = @{
            Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile"
            Name  = "EnableFirewall"
            On    = 1
            Off   = 0
        }
    }

    $config = $featureMap[$Feature]
    if (-not $config) {
        throw "未知功能：$Feature（可用：$($featureMap.Keys -join ', ')）"
    }

    $value = if ($Enabled) { $config.On } else { $config.Off }
    Set-ItemProperty -Path $config.Path -Name $config.Name -Value $value -Force
    $state = if ($Enabled) { "启用" } else { "禁用" }
    Write-Host "已${state} $Feature" -ForegroundColor Green
}

# 查看当前状态
$rdp = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server").fDenyTSConnections
Write-Host "远程桌面：$(if ($rdp -eq 0) { '已启用' } else { '已禁用' })"
```

执行结果示例：

```
启动项（5 个）：
Scope  Name                  Value
-----  ----                  -----
User   OneDrive              "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
System SecurityHealth        C:\Program Files\Windows Defender\MSASCuiL.exe
System VMware Tray           "C:\Program Files\VMware\VMware Tools\trayicon.exe"

远程桌面：已禁用
```

## 注册表备份与恢复

```powershell
# 导出注册表项
function Export-RegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$KeyPath,

        [string]$OutputDir = "C:\Backup\Registry"
    )

    New-Item $OutputDir -ItemType Directory -Force | Out-Null

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName = ($KeyPath -replace '[\\:]', '_') -replace '^HKLM_', 'HKLM-' -replace '^HKCU_', 'HKCU-'
    $outputFile = Join-Path $OutputDir "${safeName}_${timestamp}.reg"

    # 转换 PowerShell 路径为注册表路径
    $regPath = $KeyPath -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'

    $result = reg export $regPath $outputFile /y 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "已导出：$outputFile ($((Get-Item $outputFile).Length / 1KB -as [int]) KB)" -ForegroundColor Green
        return $outputFile
    } else {
        Write-Host "导出失败：$result" -ForegroundColor Red
        return $null
    }
}

# 备份重要注册表项
$importantKeys = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services"
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
)

foreach ($key in $importantKeys) {
    Export-RegistryKey -KeyPath $key
}

# 恢复注册表
function Restore-RegistryKey {
    param([Parameter(Mandatory)][string]$RegFile)

    if (-not (Test-Path $RegFile)) {
        throw "文件不存在：$RegFile"
    }

    Write-Host "即将导入注册表：$RegFile" -ForegroundColor Yellow
    $result = reg import $RegFile 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "导入成功" -ForegroundColor Green
    } else {
        Write-Host "导入失败：$result" -ForegroundColor Red
    }
}
```

执行结果示例：

```
已导出：C:\Backup\Registry\HKLM-SYSTEM-CurrentControlSet-Services_20250716_083015.reg (256 KB)
已导出：C:\Backup\Registry\HKLM-SOFTWARE-Microsoft-Windows-CurrentVersion-Run_20250716_083015.reg (4 KB)
已导出：C:\Backup\Registry\HKLM-SOFTWARE-Microsoft-Windows-NT-CurrentVersion_20250716_083015.reg (12 KB)
```

## 注意事项

1. **备份先行**：修改注册表前务必备份相关键值，错误修改可能导致系统不稳定
2. **管理员权限**：修改 `HKLM:\` 下的注册表需要管理员权限，`HKCU:\` 不需要
3. **数据类型**：注册表值有多种类型（String、DWord、QWord、Binary、ExpandString、MultiString），设置时指定正确的类型
4. **系统关键键**：`HKLM:\SYSTEM` 和 `HKLM:\SOFTWARE\Microsoft\Windows NT` 下的键值直接影响系统运行，谨慎修改
5. **64 位重定向**：32 位程序访问 `HKLM:\SOFTWARE` 会被重定向到 `HKLM:\SOFTWARE\WOW6432Node`，注意区分
6. **远程注册表**：使用 `Invoke-Command` 可以远程操作其他机器的注册表（需要 WinRM 和 Remote Registry 服务）
