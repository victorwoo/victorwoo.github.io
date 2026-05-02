---
layout: post
date: 2025-10-06 08:00:00
updated: 2025-10-06 08:00:00
title: "PowerShell 技能连载 - WMI 与 CIM 查询"
description: PowerTip of the Day - WMI and CIM Queries in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- wmi
- cim
- hardware
- system-info
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

Windows 管理规范（WMI）是 Windows 平台上用于管理和查询系统信息的核心基础设施。从硬盘序列号到操作系统版本，从网络适配器状态到 BIOS 信息，WMI 几乎能访问系统的每一个角落。长期以来，PowerShell 通过 `Get-WmiObject` cmdlet 为管理员提供了便捷的 WMI 查询能力。

然而，`Get-WmiObject` 基于 DCOM/RPC 协议进行远程通信，存在防火墙配置复杂、性能开销大等问题。从 PowerShell 3.0 开始，微软引入了基于 CIM（Common Information Model）标准的新一代 cmdlet——`Get-CimInstance`。CIM cmdlet 默认使用 WS-Man（WinRM）协议，不仅更安全、更高效，而且与跨平台标准 DMTF 对齐，代表了 Windows 系统管理的未来方向。

本文将对比 WMI 和 CIM 两套 cmdlet 的使用方式，并通过实际场景演示如何用 CIM 查询硬件信息、远程管理服务器，以及构建高效的系统清单脚本。

## WMI 与 CIM 的基本对比

我们先来看两套 cmdlet 在查询本地系统信息时的差异。以下代码分别使用 `Get-WmiObject` 和 `Get-CimInstance` 获取操作系统基本信息。

```powershell
# 传统 WMI 方式（PowerShell 2.0 引入，已标记为弃用）
$os = Get-WmiObject -Class Win32_OperatingSystem
Write-Host "操作系统: $($os.Caption)"
Write-Host "版本: $($os.Version)"
Write-Host "安装日期: $($os.InstallDate)"
Write-Host "上次启动: $($os.LastBootUpTime)"

# 现代 CIM 方式（PowerShell 3.0 引入，推荐使用）
$osCim = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host "操作系统: $($osCim.Caption)"
Write-Host "版本: $($osCim.Version)"
Write-Host "安装日期: $($osCim.InstallDate)"
Write-Host "上次启动: $($osCim.LastBootUpTime)"
```

注意输出中日期格式的差异：`Get-WmiObject` 返回原始的 WMI 时间字符串（如 `20250101120000.000000+480`），而 `Get-CimInstance` 自动将其转换为可读的 `DateTime` 对象，这一点在日常使用中非常方便。

```text
操作系统: Microsoft Windows 11 Pro
版本: 10.0.26100
安装日期: 2025-01-15 10:30:00
上次启动: 2025-10-05 22:14:33
```

## 查询硬件信息

CIM 在硬件清单收集方面非常强大。下面的脚本演示了如何一次性收集 CPU、内存、磁盘和网络适配器的关键信息，并格式化输出。

```powershell
# 查询 CPU 信息
$cpu = Get-CimInstance -ClassName Win32_Processor
foreach ($proc in $cpu) {
    Write-Host "=== CPU 信息 ==="
    Write-Host "名称: $($proc.Name)"
    Write-Host "核心数: $($proc.NumberOfCores)"
    Write-Host "逻辑处理器: $($proc.NumberOfLogicalProcessors)"
    Write-Host "最大频率: $($proc.MaxClockSpeed) MHz"
    Write-Host ""
}

# 查询物理内存
$mem = Get-CimInstance -ClassName Win32_PhysicalMemory
$totalMemGB = [math]::Round(($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
Write-Host "=== 内存信息 ==="
Write-Host "总内存: ${totalMemGB} GB"
foreach ($slot in $mem) {
    $sizeGB = [math]::Round($slot.Capacity / 1GB, 2)
    Write-Host "  插槽 $($slot.DeviceLocator): ${sizeGB} GB - $($slot.Speed) MHz"
}
Write-Host ""

# 查询磁盘信息
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
Write-Host "=== 磁盘信息 ==="
foreach ($disk in $disks) {
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $percent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
    Write-Host "  盘符: $($disk.DeviceID)"
    Write-Host "  总空间: ${totalGB} GB | 剩余: ${freeGB} GB | 可用率: ${percent}%"
    Write-Host ""
}
```

这段脚本展示了 CIM 查询的典型模式：用 `-ClassName` 指定 WMI 类名，用 `-Filter` 进行服务端筛选（比客户端 `Where-Object` 更高效），然后用 `foreach` 遍历结果进行格式化输出。

```text
=== CPU 信息 ===
名称: Intel(R) Core(TM) i7-14700K
核心数: 20
逻辑处理器: 28
最大频率: 5600 MHz

=== 内存信息 ===
总内存: 32 GB
  插槽 DIMM_A0: 16 GB - 5600 MHz
  插槽 DIMM_B0: 16 GB - 5600 MHz

=== 磁盘信息 ===
  盘符: C:
  总空间: 512 GB | 剩余: 234.56 GB | 可用率: 45.8%

  盘符: D:
  总空间: 2048 GB | 剩余: 1567.89 GB | 可用率: 76.6%
```

## 使用 CIM 会话进行远程查询

CIM 相比 WMI 的一大优势是远程管理的简便性。通过 `CimSession`，你可以同时管理多台服务器，并且可以选择 DCOM 或 WinRM 协议。这在管理老旧系统（不支持 WinRM）时特别有用。

```powershell
# 定义目标服务器列表
$servers = @("SRV-DC01", "SRV-WEB01", "SRV-DB01")

# 创建 CIM 会话（默认使用 WinRM）
$sessions = New-CimSession -ComputerName $servers -ErrorAction SilentlyContinue

# 批量查询所有服务器的操作系统和内存使用情况
$results = foreach ($session in $sessions) {
    $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
    foreach ($item in $os) {
        $totalMemGB = [math]::Round($item.TotalVisibleMemorySize / 1MB, 2)
        $freeMemGB = [math]::Round($item.FreePhysicalMemory / 1MB, 2)
        $memUsage = [math]::Round(($item.TotalVisibleMemorySize - $item.FreePhysicalMemory) / $item.TotalVisibleMemorySize * 100, 1)

        [PSCustomObject]@{
            Server     = $session.ComputerName
            OS         = $item.Caption
            TotalMemGB = $totalMemGB
            FreeMemGB  = $freeMemGB
            MemUsage   = "$memUsage%"
            Uptime     = (Get-Date) - $item.LastBootUpTime
        }
    }
}

# 输出结果表格
$results | Format-Table -AutoSize

# 使用完毕后关闭会话
Remove-CimSession -CimSession $sessions
```

上面的脚本展示了 CIM 会话的完整生命周期：创建会话、执行查询、格式化输出、最后清理会话。注意 `New-CimSession` 一次性建立了到所有服务器的连接，后续查询复用这些连接，避免了重复认证的开销。

```text
Server   OS                                    TotalMemGB FreeMemGB MemUsage Uptime
------   --                                    ---------- --------- -------- ------
SRV-DC01 Microsoft Windows Server 2022 Standard 32.00     12.45     61.1%    45.12:34:56
SRV-WEB01 Microsoft Windows Server 2022 Datacenter 64.00  28.90     54.8%    12.08:15:30
SRV-DB01 Microsoft Windows Server 2025 Standard 128.00    45.67     64.3%    02.16:42:18
```

## 使用 WQL 筛选与高级查询

WQL（WMI Query Language）是一种类似 SQL 的查询语言，可以在服务端完成数据过滤，减少网络传输量。`Get-CimInstance` 的 `-Filter` 参数接受简化的 WQL 条件，而 `-Query` 参数则支持完整的 WQL 语句。

```powershell
# 使用 -Filter 参数进行简单筛选（推荐方式）
# 查找所有已启用但未连接的网络适配器
$disconnectedAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter `
    -Filter "NetEnabled = true AND NetConnectionStatus != 2"

foreach ($adapter in $disconnectedAdapters) {
    Write-Host "适配器: $($adapter.Name)"
    Write-Host "  MAC 地址: $($adapter.MACAddress)"
    Write-Host "  速度: $([math]::Round($adapter.Speed / 1Mbps, 2)) Mbps"
    Write-Host "  状态: 未连接"
    Write-Host ""
}

# 使用 -Query 参数执行完整的 WQL 查询
# 查找启动类型为自动但当前未运行的服务
$stoppedAutoServices = Get-CimInstance -Query @"
SELECT Name, DisplayName, State, StartMode
FROM Win32_Service
WHERE StartMode = 'Auto' AND State != 'Running'
"@

Write-Host "=== 未运行的自动启动服务 ==="
foreach ($svc in $stoppedAutoServices) {
    Write-Host "  [$($svc.Name)] $($svc.DisplayName) - 状态: $($svc.State)"
}

# 关联查询：通过 __RELPATH 获取关联的磁盘分区
$diskDrive = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object -First 1
$partitions = Get-CimAssociatedInstance -InputObject $diskDrive -ResultClassName Win32_DiskPartition

Write-Host ""
Write-Host "=== 磁盘分区关联查询 ==="
Write-Host "磁盘: $($diskDrive.Model)"
foreach ($part in $partitions) {
    Write-Host "  分区 $($part.Name): $($part.Size / 1GB -as [int]) GB - 类型: $($part.Type)"
}
```

`Get-CimAssociatedInstance` 是 CIM cmdlet 的独有功能，用于遍历 WMI 对象之间的关联关系。传统 WMI cmdlet 没有直接等价的方法，需要手动构造关联查询，这也是推荐迁移到 CIM 的重要理由之一。

```text
适配器: Intel(R) Ethernet Controller I225-V
  MAC 地址: AA:BB:CC:DD:EE:FF
  速度: 1000 Mbps
  状态: 未连接

=== 未运行的自动启动服务 ===
  [Spooler] Print Spooler - 状态: Stopped
  [WSearch] Windows Search - 状态: Stopped

=== 磁盘分区关联查询 ===
磁盘: Samsung SSD 990 PRO 2TB
  分区 磁盘 #0，分区 #0: 512 GB - 类型: GPT: System
  分区 磁盘 #0，分区 #1: 1536 GB - 类型: GPT: Basic Data
```

## 构建系统清单报告

将前面的知识综合起来，我们可以构建一个实用的系统清单报告脚本。这个脚本收集关键系统信息并生成结构化的报告对象。

```powershell
function Get-SystemInventory {
    <#
    .SYNOPSIS
    收集本地或远程系统的硬件和软件清单信息。
    #>
    param(
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    $session = New-CimSession -ComputerName $ComputerName -ErrorAction Stop

    foreach ($s in $session) {
        $os = Get-CimInstance -CimSession $s -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -CimSession $s -ClassName Win32_ComputerSystem
        $bios = Get-CimInstance -CimSession $s -ClassName Win32_BIOS
        $cpus = Get-CimInstance -CimSession $s -ClassName Win32_Processor
        $disks = Get-CimInstance -CimSession $s -ClassName Win32_LogicalDisk -Filter "DriveType=3"

        $cpuNames = @()
        foreach ($cpu in $cpus) {
            $cpuNames += "$($cpu.Name) ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T)"
        }

        $diskInfo = @()
        foreach ($disk in $disks) {
            $diskInfo += [PSCustomObject]@{
                Drive   = $disk.DeviceID
                Label   = $disk.VolumeName
                TotalGB = [math]::Round($disk.Size / 1GB, 1)
                FreeGB  = [math]::Round($disk.FreeSpace / 1GB, 1)
                Percent = "$([math]::Round($disk.FreeSpace / $disk.Size * 100, 1))%"
            }
        }

        $totalMemGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        $uptime = (Get-Date) - $os.LastBootUpTime

        [PSCustomObject]@{
            ComputerName = $s.ComputerName
            Manufacturer = $cs.Manufacturer
            Model        = $cs.Model
            SerialNumber = $bios.SerialNumber
            BIOSVersion  = $bios.SMBIOSBIOSVersion
            OS           = $os.Caption
            OSBuild      = $os.BuildNumber
            CPUs         = $cpuNames -join "; "
            TotalMemGB   = $totalMemGB
            Disks        = $diskInfo
            BootTime     = $os.LastBootUpTime
            Uptime       = "{0:dd}天 {0:hh}时 {0:mm}分" -f $uptime
        }
    }

    Remove-CimSession -CimSession $session
}

# 执行清单收集并查看结果
$inventory = Get-SystemInventory
$inventory | Format-List ComputerName, Manufacturer, Model, SerialNumber, BIOSVersion, OS, OSBuild, CPUs, TotalMemGB, BootTime, Uptime
$inventory.Disks | Format-Table -AutoSize
```

这个函数展示了 CIM 查询的工程化实践：参数化的计算机名、会话复用、错误处理、结构化输出对象。你可以将它放入自己的工具模块中，在日常运维中反复调用。

```text
ComputerName : DESKTOP-WORKSTATION
Manufacturer : Gigabyte Technology Co., Ltd.
Model        : Z790 AORUS MASTER
SerialNumber : GG2401001234
BIOSVersion  : F12
OS           : Microsoft Windows 11 Pro
OSBuild      : 26100
CPUs         : Intel(R) Core(TM) i7-14700K (20C/28T)
TotalMemGB   : 32
BootTime     : 2025-10-05 22:14:33
Uptime       : 00天 09时 45分

Drive Label       TotalGB FreeGB Percent
----- -----       ------- ------ -------
C:    Windows       512.0  234.6 45.8%
D:    Data         2048.0 1567.9 76.6%
E:    Backup       4096.0 3890.2 95.0%
```

## 注意事项

1. **优先使用 CIM cmdlet**：`Get-WmiObject` 在 PowerShell 5.1 中已标记为弃用，在 PowerShell 7 的 Windows 版本中仍然可用但建议迁移。新项目应一律使用 `Get-CimInstance`、`Invoke-CimMethod` 等 CIM 系列 cmdlet。

2. **服务端筛选优于客户端筛选**：始终优先使用 `-Filter` 参数在服务端过滤数据（如 `-Filter "DriveType=3"`），而不是将全部结果拉回本地再用 `Where-Object` 过滤。前者只传输需要的数据，后者在 WMI 类数据量大时会产生明显的性能差距。

3. **CIM 会话需要清理**：通过 `New-CimSession` 创建的会话在使用完毕后务必调用 `Remove-CimSession` 释放资源。未清理的会话会占用服务器端的 WinRM 连接配额，在大量并发场景下可能导致后续连接失败。

4. **注意 DCOM 回退场景**：如果目标机器不支持 WinRM（如老旧的 Windows Server 2003），可以在 `New-CimSession` 时通过 `-SessionOption` 指定 DCOM 协议：`New-CimSessionOption -Protocol Dcom`。但 DCOM 的端口配置更复杂，防火墙规则更多，建议统一部署 WinRM。

5. **WMI 类名大小写不敏感但保持一致**：PowerShell 中 `Win32_OperatingSystem` 和 `win32_operatingsystem` 效果相同，但在脚本中应统一使用 PascalCase 命名（如 `Win32_OperatingSystem`），以提高代码可读性和团队协作一致性。

6. **远程查询需要管理员权限**：无论是 WMI 还是 CIM，远程查询都需要目标机器的本地管理员权限，并且 WinRM 服务必须处于运行状态。可以使用 `Test-WSMan` 命令快速验证远程机器的 WinRM 连通性。
