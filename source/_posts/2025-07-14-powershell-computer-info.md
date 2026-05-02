---
layout: post
date: 2025-07-14 08:00:00
updated: 2025-07-14 08:00:00
title: "PowerShell 技能连载 - 系统信息采集"
description: PowerTip of the Day - System Information Collection in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- system-management
- inventory
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

系统信息采集是运维工作的基础——新服务器上架时的资产登记、故障排查时的环境确认、容量规划时的硬件盘点、合规审计时的配置核查。PowerShell 通过 CIM/WMI、.NET 类和注册表，可以获取几乎所有的系统信息：硬件配置、操作系统详情、网络设置、已安装软件、驱动版本等。

本文将讲解如何高效采集系统信息，并生成可用的资产报告。

<!-- more -->

## 硬件信息采集

```powershell
# 计算机基本信息
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS

Write-Host "=== 系统概览 ===" -ForegroundColor Cyan
Write-Host "计算机名：$($cs.Name)"
Write-Host "制造商：$($cs.Manufacturer)"
Write-Host "型号：$($cs.Model)"
Write-Host "序列号：$($bios.SerialNumber)"
Write-Host "操作系统：$($os.Caption)"
Write-Host "版本：$($os.Version)"
Write-Host "架构：$($os.OSArchitecture)"
Write-Host "安装日期：$($os.InstallDate.ToString('yyyy-MM-dd'))"
Write-Host "最后启动：$($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "运行时间：$([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)) 天"

# CPU 信息
Write-Host "`n=== CPU 信息 ===" -ForegroundColor Cyan
$cpus = Get-CimInstance Win32_Processor
foreach ($cpu in $cpus) {
    Write-Host "处理器：$($cpu.Name)"
    Write-Host "  核心数：$($cpu.NumberOfCores)，线程数：$($cpu.NumberOfLogicalProcessors)"
    Write-Host "  频率：$($cpu.MaxClockSpeed) MHz"
    Write-Host "  使用率：$($cpu.LoadPercentage)%"
}

# 内存信息
Write-Host "`n=== 内存信息 ===" -ForegroundColor Cyan
$totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGB = [math]::Round($totalGB - $freeGB, 2)
$usedPct = [math]::Round($usedGB / $totalGB * 100, 1)

Write-Host "总内存：$totalGB GB"
Write-Host "已使用：$usedGB GB ($usedPct%)"
Write-Host "可用：$freeGB GB"

# 物理内存条详情
$dimms = Get-CimInstance Win32_PhysicalMemory
foreach ($dimm in $dimms) {
    $sizeGB = [math]::Round($dimm.Capacity / 1GB)
    Write-Host "  槽位 $($dimm.DeviceLocator)：$sizeGB GB $($dimm.Speed) MHz $($dimm.Manufacturer)"
}
```

执行结果示例：

```
=== 系统概览 ===
计算机名：SRV-PROD-01
制造商：Dell Inc.
型号：PowerEdge R750
序列号：ABC123DEF456
操作系统：Microsoft Windows Server 2022 Standard
版本：10.0.20348
架构：64 位
安装日期：2024-03-15
最后启动：2025-06-28 02:00:00
运行时间：16.2 天

=== CPU 信息 ===
处理器：Intel(R) Xeon(R) Gold 6348 CPU @ 2.60GHz
  核心数：28，线程数：56
  频率：2600 MHz
  使用率：35%

=== 内存信息 ===
总内存：256 GB
已使用：185.4 GB (72.4%)
可用：70.6 GB
  槽位 DIMM_A1：32 GB 3200 MHz Samsung
  槽位 DIMM_A2：32 GB 3200 MHz Samsung
  槽位 DIMM_B1：32 GB 3200 MHz Samsung
  槽位 DIMM_B2：32 GB 3200 MHz Samsung
```

## 磁盘与网络信息

```powershell
# 磁盘信息
Write-Host "=== 磁盘信息 ===" -ForegroundColor Cyan
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disk in $disks) {
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedPct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)
    $bar = "|" + ("█" * [math]::Floor($usedPct / 5)) + ("░" * (20 - [math]::Floor($usedPct / 5))) + "|"

    Write-Host "$($disk.DeviceID) $bar $usedPct% ($freeGB GB 可用 / $totalGB GB)"
}

# 网络适配器
Write-Host "`n=== 网络适配器 ===" -ForegroundColor Cyan
$adapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -and $_.NetEnabled }
foreach ($adapter in $adapters) {
    Write-Host "适配器：$($adapter.Name)"
    Write-Host "  MAC：$($adapter.MACAddress)"
    Write-Host "  速度：$([math]::Round($adapter.Speed / 1GBps, 2)) Gbps"

    $config = Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object { $_.Index -eq $adapter.Index }
    if ($config.IPAddress) {
        Write-Host "  IP：$($config.IPAddress -join ', ')"
        Write-Host "  网关：$($config.DefaultIPGateway -join ', ')"
        Write-Host "  DNS：$($config.DNSServerSearchOrder -join ', ')"
    }
}
```

执行结果示例：

```
=== 磁盘信息 ===
C: |████████████████░░░░| 78.5% (43.2 GB 可用 / 200.0 GB)
D: |█████████░░░░░░░░░░░| 47.3% (263.5 GB 可用 / 500.0 GB)
E: |████████████░░░░░░░░| 62.1% (379.0 GB 可用 / 1000.0 GB)

=== 网络适配器 ===
适配器：Intel(R) Ethernet Connection X722
  MAC：AA:BB:CC:DD:EE:01
  速度：10 Gbps
  IP：10.0.1.10
  网关：10.0.1.1
  DNS：10.0.1.100, 10.0.1.101
```

## 已安装软件清单

```powershell
# 获取已安装软件列表
function Get-InstalledSoftware {
    param(
        [string]$SearchName,
        [switch]$WithUpdates
    )

    $software = @()

    # 从注册表读取（64位和32位）
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $regPaths) {
        $items = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName }
        foreach ($item in $items) {
            $software += [PSCustomObject]@{
                Name        = $item.DisplayName
                Version     = $item.DisplayVersion
                Publisher   = $item.Publisher
                InstallDate = if ($item.InstallDate) {
                    try { [datetime]::ParseExact($item.InstallDate, "yyyyMMdd", $null) } catch { $null }
                } else { $null }
                Size        = if ($item.EstimatedSize) {
                    [math]::Round($item.EstimatedSize / 1024, 1)
                } else { $null }
            }
        }
    }

    # 去重并排序
    $software = $software | Sort-Object Name -Unique | Sort-Object Name

    if ($SearchName) {
        $software = $software | Where-Object { $_.Name -match [regex]::Escape($SearchName) }
    }

    return $software
}

# 列出所有软件
$all = Get-InstalledSoftware
Write-Host "已安装软件：$($all.Count) 个" -ForegroundColor Cyan
$all | Select-Object Name, Version, Publisher |
    Format-Table -AutoSize | Out-String -Width 120 | Write-Host

# 搜索特定软件
$java = Get-InstalledSoftware -SearchName "Java"
Write-Host "`nJava 相关软件：" -ForegroundColor Yellow
$java | Format-Table Name, Version -AutoSize
```

执行结果示例：

```
已安装软件：127 个
Name                            Version      Publisher
----                            -------      ----------
7-Zip 23.01 (x64)              23.01        Igor Pavlov
Git for Windows                 2.45.0       The Git Development Community
Microsoft Visual Studio Code    1.90.1       Microsoft Corporation
Node.js                         20.14.0      OpenJS Foundation
PowerShell 7-x64                7.4.2        Microsoft Corporation

Java 相关软件：
Name                        Version
----                        -------
Java 8 Update 411 (64-bit)  8.0.4110.9
Java SE Development Kit 17  17.0.11
```

## 系统信息报告函数

```powershell
function Get-SystemReport {
    <#
    .SYNOPSIS
    生成完整的系统信息报告
    #>
    param([string]$OutputPath = "C:\Reports\system-info.json")

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

    $report = [PSCustomObject]@{
        CollectedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Computer = @{
            Name       = $cs.Name
            Manufacturer = $cs.Manufacturer
            Model      = $cs.Model
            Serial     = $bios.SerialNumber
            Domain     = $cs.Domain
        }
        OS = @{
            Name       = $os.Caption
            Version    = $os.Version
            Architecture = $os.OSArchitecture
            InstallDate = $os.InstallDate.ToString("yyyy-MM-dd")
            LastBoot   = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
            UptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
        }
        CPU = @{
            Name       = $cpu.Name
            Cores      = $cpu.NumberOfCores
            Threads    = $cpu.NumberOfLogicalProcessors
            UsagePct   = $cpu.LoadPercentage
        }
        Memory = @{
            TotalGB    = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            FreeGB     = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            UsagePct   = [math]::Round(($cs.TotalPhysicalMemory - $os.FreePhysicalMemory * 1MB) / $cs.TotalPhysicalMemory * 100, 1)
        }
        Disks = @(foreach ($disk in (Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3")) {
            @{
                Drive     = $disk.DeviceID
                TotalGB   = [math]::Round($disk.Size / 1GB, 2)
                FreeGB    = [math]::Round($disk.FreeSpace / 1GB, 2)
                UsagePct  = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)
            }
        })
    }

    $report | ConvertTo-Json -Depth 5 | Set-Content $OutputPath -Encoding UTF8
    Write-Host "系统报告已保存：$OutputPath" -ForegroundColor Green

    return $report
}

Get-SystemReport | Select-Object -Property CollectedAt |
    Format-List
```

执行结果示例：

```
系统报告已保存：C:\Reports\system-info.json

CollectedAt : 2025-07-14 08:00:00
```

## 注意事项

1. **权限要求**：部分信息（如序列号）需要管理员权限才能读取
2. **远程采集**：使用 `-ComputerName` 参数可以远程采集其他机器的信息（需要 WinRM）
3. **WMI vs CIM**：优先使用 `Get-CimInstance`（标准 WS-Man 协议），避免使用已过时的 `Get-WmiObject`
4. **性能考虑**：某些查询（如软件清单）需要遍历注册表，在大量机器上并行执行时注意时间
5. **输出格式**：JSON 适合程序处理，HTML 适合人类阅读，CSV 适合导入 Excel
6. **敏感信息**：序列号、IP 地址等信息属于敏感数据，报告存储和传输时注意保护
