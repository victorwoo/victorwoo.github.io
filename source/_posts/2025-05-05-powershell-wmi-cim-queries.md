---
layout: post
date: 2025-05-05 08:00:00
updated: 2025-05-05 08:00:00
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
- system-management
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

Windows Management Instrumentation（WMI）是 Windows 操作系统内置的管理信息基础设施，它以统一的接口暴露了硬件、操作系统、应用程序的海量信息——从 CPU 温度到磁盘健康状态，从进程列表到安装的补丁，几乎所有系统信息都可以通过 WMI 获取。PowerShell 通过 CIM（Common Information Model）cmdlet 提供了对 WMI 的现代化访问方式。

本文将系统讲解 WMI/CIM 的核心概念、查询语法、常用场景，以及如何构建高效的信息采集脚本。

<!-- more -->

## WMI 与 CIM 的关系

WMI 是微软对 WBEM（Web-Based Enterprise Management）标准的实现，而 CIM 是 WMI 底层的数据模型。PowerShell 提供了两套 cmdlet 来访问 WMI 数据：

- **旧版 WMI cmdlet**：`Get-WmiObject`、`Invoke-WmiMethod` 等（已弃用）
- **新版 CIM cmdlet**：`Get-CimInstance`、`Invoke-CimMethod` 等（推荐）

CIM cmdlet 的优势在于：支持 WinRM 远程连接（而非 DCOM）、更好的序列化、与 WS-Man 协议兼容。所有新脚本都应使用 CIM cmdlet。

```powershell
# 查看可用的 CIM 类数量
$cimClasses = Get-CimClass | Select-Object -ExpandProperty CimClassName
Write-Host "系统中共有 $($cimClasses.Count) 个 CIM 类"

# 搜索与磁盘相关的 CIM 类
Get-CimClass -ClassName *Disk* | Select-Object CimClassName |
    Format-Table -AutoSize
```

执行结果示例：

```
系统中共有 1287 个 CIM 类

CimClassName
------------
Win32_DiskDrive
Win32_LogicalDisk
Win32_DiskPartition
Win32_MappedLogicalDisk
CIM_DiskDrive
CIM_LogicalDisk
```

## 基础信息查询

最常用的场景是查询系统硬件和操作系统信息。以下示例展示了如何获取关键的系统信息：

```powershell
# 操作系统信息
$os = Get-CimInstance -ClassName Win32_OperatingSystem
[PSCustomObject]@{
    系统       = $os.Caption
    版本       = $os.Version
    架构       = $os.OSArchitecture
    计算机名   = $os.CSName
    安装日期   = $os.InstallDate.ToString('yyyy-MM-dd')
    最后启动   = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
    可用内存GB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    总内存GB   = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
}
```

执行结果示例：

```
系统       : Microsoft Windows 11 Pro
版本       : 10.0.22631
架构       : 64-bit
计算机名   : DESKTOP-WORK01
安装日期   : 2024-03-15
最后启动   : 2025-05-04 08:30:00
可用内存GB : 8.45
总内存GB   : 31.89
```

```powershell
# CPU 信息
Get-CimInstance -ClassName Win32_Processor |
    Select-Object Name, NumberOfCores, NumberOfLogicalProcessors,
        MaxClockSpeed, L2CacheSize, L3CacheSize |
    Format-List

# BIOS 信息（含序列号，适合资产盘点）
Get-CimInstance -ClassName Win32_BIOS |
    Select-Object SerialNumber, Manufacturer, SMBIOSBIOSVersion, ReleaseDate

# 主板信息
Get-CimInstance -ClassName Win32_BaseBoard |
    Select-Object Manufacturer, Product, SerialNumber, Version
```

执行结果示例：

```
Name                    : Intel(R) Core(TM) i7-13700K
NumberOfCores           : 16
NumberOfLogicalProcessors: 24
MaxClockSpeed           : 3400
L2CacheSize             : 24576
L3CacheSize             : 30720

SerialNumber       : BTFC427001XZ
Manufacturer       : American Megatrends International, LLC.
SMBIOSBIOSVersion  : 1.28.0
ReleaseDate        : 2025-01-15

Manufacturer : ASUSTeK COMPUTER INC.
Product      : ProArt Z790-CREATOR
SerialNumber : 2308475091
Version      : Rev 1.xx
```

## 使用 WQL 过滤查询

WQL（WMI Query Language）是类似 SQL 的查询语言，可以在服务端过滤数据，减少网络传输量。对于远程查询，使用 `-Filter` 参数比在客户端用 `Where-Object` 过滤高效得多。

```powershell
# 查找所有固定磁盘（非可移动、非网络驱动器）
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{N='容量GB'; E={[math]::Round($_.Size/1GB,2)}},
        @{N='已用GB'; E={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
        @{N='可用GB'; E={[math]::Round($_.FreeSpace/1GB,2)}},
        @{N='使用率%'; E={[math]::Round(($_.Size - $_.FreeSpace)/$_.Size*100,1)}},
        FileSystem |
    Format-Table -AutoSize

# 查找所有运行中的服务
$runningServices = Get-CimInstance -ClassName Win32_Service -Filter "State='Running'"
Write-Host "正在运行的服务数量：$($runningServices.Count)"

# 查找占用内存超过 100MB 的进程
Get-CimInstance -ClassName Win32_Process -Filter "WorkingSetSize > 104857600" |
    Select-Object Name, ProcessId,
        @{N='内存MB'; E={[math]::Round($_.WorkingSetSize/1MB,1)}} |
    Sort-Object 内存MB -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
DeviceID 容量GB 已用GB 可用GB 使用率% FileSystem
-------- ------ ------ ------ -------- ----------
C:       476.92 285.34 191.58 59.8     NTFS
D:       931.51 642.18 289.33 68.9     NTFS

正在运行的服务数量：147

Name           ProcessId 内存MB
----           --------- ------
chrome              8234   842.3
Code               12045   624.7
msedge              5678   312.5
```

## 磁盘健康与 SMART 信息

通过 WMI 可以获取磁盘的健康状态，特别是 SSD 的磨损程度：

```powershell
# 获取物理磁盘信息
Get-CimInstance -ClassName Win32_DiskDrive |
    Select-Object Model, SerialNumber, Size,
        @{N='总容量GB'; E={[math]::Round($_.Size/1GB,2)}},
        InterfaceType, MediaType, Status |
    Format-Table -AutoSize

# 查询磁盘分区与挂载点映射
$partitions = Get-CimInstance -ClassName Win32_DiskPartition
$logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk

foreach ($disk in (Get-CimInstance -ClassName Win32_DiskDrive)) {
    Write-Host "`n磁盘：$($disk.Model)" -ForegroundColor Cyan
    Write-Host "  接口：$($disk.InterfaceType)"
    Write-Host "  大小：$([math]::Round($disk.Size/1GB,2)) GB"
    Write-Host "  状态：$($disk.Status)"
}
```

执行结果示例：

```
Model           SerialNumber      总容量GB InterfaceType MediaType  Status
-----           ------------      -------- ------------- ---------  ------
Samsung SSD 870 S4TPNF0X123456   476.92    IDE           Fixed hard  OK
WDC WD10EZEX    WD-WMC4E0K12345  931.51    IDE           Fixed hard  OK

磁盘：Samsung SSD 870 EVO 500GB
  接口：SCSI
  大小：476.92 GB
  状态：OK
```

## 网络配置查询

WMI 存储了完整的网络适配器信息，包括 IP 地址、MAC 地址、DHCP 状态等：

```powershell
# 获取活跃的网络适配器信息
Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" |
    Select-Object Description,
        @{N='IPAddress'; E={$_.IPAddress -join ', '}},
        @{N='SubnetMask'; E={$_.IPSubnet -join ', '}},
        DefaultIPGateway,
        @{N='DNSServers'; E={$_.DNSServerSearchOrder -join ', '}},
        DHCPEnabled,
        MACAddress |
    Format-List

# 查询网络适配器物理信息
Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "NetConnectionStatus=2" |
    Select-Object Name, AdapterType, Speed,
        @{N='速度Mbps'; E={[math]::Round($_.Speed/1MB,0)}} |
    Format-Table -AutoSize
```

执行结果示例：

```
Description     : Intel(R) Ethernet Controller I225-V
IPAddress       : 192.168.1.100
SubnetMask      : 255.255.255.0
DefaultIPGateway: 192.168.1.1
DNSServers      : 8.8.8.8, 8.8.4.4
DHCPEnabled     : True
MACAddress      : A0:B1:C2:D3:E4:F5

Name                          AdapterType           速度Mbps
----                          ------------           --------
Intel(R) Ethernet Controller  Ethernet 802.3           1000
```

## 软件与补丁查询

WMI 是获取已安装软件和系统补丁信息的重要来源：

```powershell
# 查询已安装的软件
Get-CimInstance -ClassName Win32_Product |
    Select-Object Name, Version, Vendor, InstallDate |
    Sort-Object Name |
    Format-Table -AutoSize

# 查询最近的系统更新
Get-CimInstance -ClassName Win32_QuickFixEngineering |
    Sort-Object InstalledOn -Descending |
    Select-Object -First 10 HotFixID, Description, InstalledOn |
    Format-Table -AutoSize

# 检查特定 KB 是否已安装
$kb = 'KB5034441'
$installed = Get-CimInstance -ClassName Win32_QuickFixEngineering -Filter "HotFixID='$kb'"
if ($installed) {
    Write-Host "$kb 已安装于 $($installed.InstalledOn.ToString('yyyy-MM-dd'))" -ForegroundColor Green
} else {
    Write-Host "$kb 未安装" -ForegroundColor Red
}
```

执行结果示例：

```
Name                    Version    Vendor          InstallDate
----                    -------    ------          -----------
Microsoft Visual C++... 14.40.33... Microsoft Co... 2025-01-10
7-Zip 24.08 (x64)      24.08      Igor Pavlov    2025-02-15
Mozilla Firefox         125.0.1    Mozilla        2025-04-20

HotFixID   Description       InstalledOn
--------   -----------       -----------
KB5036908  Security Update   2025-04-25
KB5036892  Update            2025-04-22
KB5034441  Security Update   2025-04-10

KB5034441 已安装于 2025-04-10
```

> **注意**：`Win32_Product` 查询会触发 Windows Installer 重新配置检查，速度很慢且可能影响系统稳定性。对于软件清单，建议改用注册表查询 `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`。

## 构建系统信息采集函数

将常用的 WMI 查询封装为可复用函数，方便在运维脚本中调用：

```powershell
function Get-SystemInventory {
    <#
    .SYNOPSIS
    采集系统完整信息用于资产盘点
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $session = New-CimSession -ComputerName $ComputerName

    $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem
    $cpu = Get-CimInstance -CimSession $session -ClassName Win32_Processor
    $disk = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    $bios = Get-CimInstance -CimSession $session -ClassName Win32_BIOS

    $result = [PSCustomObject]@{
        ComputerName   = $cs.Name
        Manufacturer   = $cs.Manufacturer
        Model          = $cs.Model
        SerialNumber   = $bios.SerialNumber
        OS             = $os.Caption
        OSVersion      = $os.Version
        Architecture   = $os.OSArchitecture
        InstallDate    = $os.InstallDate.ToString('yyyy-MM-dd')
        LastBoot       = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
        UptimeDays     = [math]::Round((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
        CPU            = $cpu.Name
        CPUCores       = $cpu.NumberOfCores
        CPULogical     = $cpu.NumberOfLogicalProcessors
        TotalRAM_GB    = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        FreeRAM_GB     = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        Disks          = $disk | ForEach-Object {
            [PSCustomObject]@{
                Drive   = $_.DeviceID
                SizeGB  = [math]::Round($_.Size/1GB, 2)
                FreeGB  = [math]::Round($_.FreeSpace/1GB, 2)
                UsedPct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
            }
        }
    }

    Remove-CimSession -CimSession $session
    $result
}

# 采集本机信息
Get-SystemInventory | Format-List
```

执行结果示例：

```
ComputerName : DESKTOP-WORK01
Manufacturer : ASUSTeK COMPUTER INC.
Model        : ProArt Z790-CREATOR
SerialNumber : 2308475091
OS           : Microsoft Windows 11 Pro
OSVersion    : 10.0.22631
Architecture : 64-bit
InstallDate  : 2024-03-15
LastBoot     : 2025-05-04 08:30:00
UptimeDays   : 1.1
CPU          : Intel(R) Core(TM) i7-13700K
CPUCores     : 16
CPULogical   : 24
TotalRAM_GB  : 31.89
FreeRAM_GB   : 8.45
Disks        : {@{Drive=C:; SizeGB=476.92; FreeGB=191.58; UsedPct=59.8}, @{Drive=D:; SizeGB=931.51; FreeGB=289.33; UsedPct=68.9}}
```

## 注意事项

1. **优先使用 CIM cmdlet**：`Get-CimInstance` 优于 `Get-WmiObject`，后者在 PowerShell 7 中已被弃用
2. **远程连接方式**：CIM cmdlet 默认使用 WS-Man（WinRM）协议，兼容性优于旧版 DCOM；可用 `New-CimSession` 建立持久会话
3. **WQL 过滤**：使用 `-Filter` 参数在服务端过滤数据，比管道 `Where-Object` 更高效，尤其对远程查询
4. **避免频繁查询 Win32_Product**：该类会触发 Windows Installer 重新配置，可能导致短暂的系统卡顿
5. **权限要求**：部分 WMI 类（如安全相关）需要管理员权限才能查询
6. **CIM 会话管理**：批量查询时使用 `New-CimSession` 建立持久会话，避免每次查询都建立新连接
