---
layout: post
date: 2026-03-25 08:00:00
updated: 2026-03-25 08:00:00
title: "PowerShell 技能连载 - CIM/WMI 高级查询"
description: PowerTip of the Day - Advanced CIM/WMI Queries in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- cim
- wmi
- hardware
- inventory
---

_适用于 PowerShell 5.1 及以上版本_

在 Windows 系统管理中，CIM（Common Information Model）和 WMI（Windows Management Instrumentation）是获取系统底层信息的核心接口。日常运维中我们经常使用 `Get-CimInstance` 来查询服务状态、磁盘信息等，但这仅仅是冰山一角。CIM 提供的高级查询能力——WQL 查询语言、关联遍历、事件订阅、远程会话管理——可以让你对整个 Windows 基础设施进行深度洞察。

对于管理数十台甚至上百台服务器的运维团队来说，掌握 CIM 高级查询技术意味着可以用更少的代码获取更精确的系统信息。通过 WQL 的 WHERE 子句在服务端完成数据过滤，比在客户端用 `Where-Object` 筛选效率高出数倍；通过 CIM 事件订阅可以实现文件变更监控、进程启停追踪等实时告警；通过 CIM 会话（CimSession）可以高效地批量管理远程主机。

本文将从 WQL 查询优化、硬件资产清单采集、CIM 事件订阅与远程管理三个维度，带你深入挖掘 CIM/WMI 的高级用法。

## WQL 查询与性能优化

WQL（WMI Query Language）是专用于 WMI/CIM 的查询语言，语法类似 SQL，支持 SELECT、FROM、WHERE 等子句。很多用户习惯先获取全部实例再用 PowerShell 过滤，这在大规模查询时会产生大量不必要的数据传输。正确的做法是把过滤条件交给 WQL，让 WMI 服务端只返回符合条件的记录。

```powershell
# ============================================================
# WQL 查询性能优化示例
# ============================================================

# 1. 基本查询：获取所有磁盘信息（低效写法）
$allDisks = Get-CimInstance -ClassName Win32_LogicalDisk
$filtered = $allDisks | Where-Object { $_.DriveType -eq 3 -and $_.FreeSpace -lt 1GB }
$filtered | Select-Object DeviceID, `
    @{N='TotalGB';E={[math]::Round($_.Size/1GB,2)}}, `
    @{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,2)}}, `
    @{N='UsedPct';E={[math]::Round(($_.Size - $_.FreeSpace)/$_.Size*100,1)}}

# 2. WQL 优化写法：服务端过滤，仅返回本地磁盘且空间不足的记录
$query = "SELECT DeviceID, Size, FreeSpace, VolumeName " +
         "FROM Win32_LogicalDisk " +
         "WHERE DriveType=3 AND FreeSpace < 1073741824"
$wqlResult = Get-CimInstance -Query $query
$wqlResult | Select-Object DeviceID, VolumeName, `
    @{N='TotalGB';E={[math]::Round($_.Size/1GB,2)}}, `
    @{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,2)}}

# 3. 仅选择需要的属性（减少返回数据量）
Get-CimInstance -ClassName Win32_Process -Property Name, ProcessId, WorkingSetSize |
    Sort-Object WorkingSetSize -Descending |
    Select-Object -First 10 Name, ProcessId,
        @{N='MemMB';E={[math]::Round($_.WorkingSetSize/1MB,1)}}

# 4. LIKE 模糊查询：查找所有包含 "SQL" 的服务
Get-CimInstance -Query `
    "SELECT Name, State, StartMode FROM Win32_Service WHERE Name LIKE '%SQL%'" |
    Select-Object Name, State, StartMode

# 5. 关联查询：获取磁盘分区与逻辑磁盘的对应关系
Get-CimInstance -Query `
    "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\\\.\\PHYSICALDRIVE0'} " +
    "WHERE ResultClass=Win32_DiskPartition" |
    Select-Object DeviceID, Type, Size, Bootable
```

执行结果示例：

```
DeviceID VolumeName TotalGB FreeGB UsedPct
-------- ---------- ------- ------ -------
C:       System     256.00   0.85    99.7
E:       Data       500.00   0.32    99.9

Name                ProcessId  MemMB
----                ---------  -----
chrome               12840    812.3
devenv                9456    624.7
Code                 10234    418.2

Name                    State   StartMode
----                    -----   ---------
MSSQLSERVER             Running Auto
SQLSERVERAGENT          Stopped Manual
SQLBrowser              Running Auto
SQLTELEMETRY            Running Auto

DeviceID       Type             Size      Bootable
--------       ----             ----      --------
Disk #0, Part. 0 Installable File Sys. 524288000   True
Disk #0, Part. 1 GPT: Basic Data   274877906944  False
```

上面的代码展示了五种不同层次的查询优化技巧。第一种是"反面教材"——先全量拉取再客户端过滤；第二种用 WQL 的 WHERE 子句在服务端完成过滤，显著减少网络传输和内存占用；第三种通过 `-Property` 参数限定返回字段；第四种演示 WQL 的 LIKE 模糊匹配；第五种用 ASSOCIATORS OF 语句实现跨类关联查询，可以沿着 CIM 模型的关系树遍历关联对象。

## 硬件资产清单采集

硬件资产清点是 IT 运维中的高频需求。通过 CIM 可以采集 CPU、内存、磁盘、网络适配器、BIOS、操作系统等完整的硬件和软件信息。下面的脚本将多种 CIM 查询组合在一起，生成一份结构化的资产报告。

```powershell
# ============================================================
# 完整硬件资产清单采集脚本
# ============================================================

function Get-SystemInventory {
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $report = [ordered]@{}
    $report['ComputerName'] = $ComputerName
    $report['ScanTime'] = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # 1. 操作系统信息
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
    $report['OSName']     = $os.Caption
    $report['OSVersion']  = $os.Version
    $report['OSArch']     = $os.OSArchitecture
    $report['InstallDate']= $os.InstallDate.ToString('yyyy-MM-dd')
    $report['LastBoot']   = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
    $report['UptimeDays'] = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
    $report['TotalMemGB'] = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $report['FreeMemGB']  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $report['MemUsagePct']= [math]::Round(
        ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) /
        $os.TotalVisibleMemorySize * 100, 1)

    # 2. CPU 信息
    $cpus = Get-CimInstance -ClassName Win32_Processor -ComputerName $ComputerName
    $report['CPUCount'] = $cpus.Count
    $report['CPUDetails'] = $cpus | ForEach-Object {
        [PSCustomObject]@{
            Name     = $_.Name
            Cores    = "$($_.NumberOfCores)C/$($_.NumberOfLogicalProcessors)T"
            MaxClock = "$([math]::Round($_.MaxClockSpeed/1000,1)) GHz"
            L2Cache  = "$($_.L2CacheSize) KB"
            L3Cache  = "$($_.L3CacheSize) KB"
        }
    }

    # 3. 磁盘信息
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" `
        -ComputerName $ComputerName
    $report['Disks'] = $disks | ForEach-Object {
        [PSCustomObject]@{
            Drive     = $_.DeviceID
            Label     = $_.VolumeName
            TotalGB   = [math]::Round($_.Size/1GB, 2)
            FreeGB    = [math]::Round($_.FreeSpace/1GB, 2)
            UsedPct   = [math]::Round(($_.Size - $_.FreeSpace)/$_.Size*100, 1)
            FileSystem= $_.FileSystem
        }
    }

    # 4. 网络适配器（仅物理适配器）
    $query = "SELECT Name, MACAddress, NetConnectionID, Speed, NetEnabled " +
             "FROM Win32_NetworkAdapter WHERE PhysicalAdapter=True AND NetEnabled=True"
    $nics = Get-CimInstance -Query $query -ComputerName $ComputerName
    $report['NetworkAdapters'] = $nics | ForEach-Object {
        [PSCustomObject]@{
            Interface = $_.NetConnectionID
            MAC       = $_.MACAddress
            SpeedMbps = [math]::Round($_.Speed / 1000000, 0)
        }
    }

    # 5. 已安装软件（含版本和安装日期）
    $software = Get-CimInstance -ClassName Win32_Product -ComputerName $ComputerName |
        Sort-Object Name |
        Select-Object -First 30 Name, Version, @{N='InstallDate';E={
            if ($_.InstallDate) { $_.InstallDate.ToString('yyyy-MM-dd') } else { 'N/A' }
        }}
    $report['InstalledSoftware'] = $software

    # 6. BIOS 和序列号（用于资产登记）
    $bios = Get-CimInstance -ClassName Win32_BIOS -ComputerName $ComputerName
    $cs   = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName
    $report['BIOSVersion']  = $bios.SMBIOSBIOSVersion
    $report['SerialNumber'] = $bios.SerialNumber
    $report['Manufacturer'] = $cs.Manufacturer
    $report['Model']        = $cs.Model

    return [PSCustomObject]$report
}

# 执行采集
$inventory = Get-SystemInventory

# 输出摘要
$inventory | Select-Object ComputerName, OSName, OSVersion, OSArch, `
    SerialNumber, Manufacturer, Model, TotalMemGB, MemUsagePct, UptimeDays

# 输出磁盘详情
$inventory.Disks | Format-Table -AutoSize

# 输出网络适配器
$inventory.NetworkAdapters | Format-Table -AutoSize
```

执行结果示例：

```
ComputerName : DESKTOP-PROD01
OSName       : Microsoft Windows 11 Enterprise
OSVersion    : 10.0.26100
OSArch       : 64-bit
SerialNumber : PF4K7X2R
Manufacturer : Dell Inc.
Model        : Precision 5680
TotalMemGB   : 32.00
MemUsagePct  : 67.3
UptimeDays   : 12.5

Drive Label     TotalGB FreeGB UsedPct FileSystem
----- -----     ------- ------ ------- ----------
C:    System      256.00  98.45    61.5 NTFS
D:    Data        512.00 187.32    63.4 NTFS
E:    Backup      1024.00 891.50   13.0 ReFS

Interface   MAC               SpeedMbps
---------   ---               ---------
Ethernet    4C:7A:DB:12:34:56      1000
Wi-Fi       4C:7A:DB:12:34:57       867
```

这个 `Get-SystemInventory` 函数封装了六大类信息的采集逻辑：操作系统概览（含运行时间和内存使用率）、CPU 详细参数（核心数、频率、缓存）、磁盘分区与使用率、活跃的网络适配器及带宽、已安装软件清单、BIOS 序列号和硬件型号。在实际运维中，你可以将此函数配合远程 CIM 会话批量采集多台主机的资产数据，汇总到 CSV 或数据库中。

注意 `Win32_Product` 类的查询会比较慢（它会触发 MSI 重新配置检查），在生产环境中如果只需要软件清单，建议改用注册表路径 `HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\` 来读取，效率会高很多。

## CIM 事件订阅与远程管理

CIM 事件订阅是 WMI 的一项强大功能，可以监控系统中特定事件的发生，例如进程创建、文件变更、服务状态变化等。配合 CimSession，我们可以实现对远程主机的高效批量管理。下面的代码演示了三种典型的 CIM 高级应用场景。

```powershell
# ============================================================
# CIM 事件订阅与远程管理
# ============================================================

# ---- 场景 1：进程创建事件监控 ----

# 注册 WMI 事件查询，每秒轮询一次，监控 notepad.exe 启动
$query = "SELECT * FROM __InstanceCreationEvent WITHIN 1 " +
         "WHERE TargetInstance ISA 'Win32_Process' " +
         "AND TargetInstance.Name = 'notepad.exe'"

$job = Register-CimIndicationEvent -Query $query -SourceIdentifier 'MonitorNotepad'

Write-Host "已注册 notepad.exe 进程监控事件..." -ForegroundColor Green
Write-Host "请打开记事本触发事件，等待 60 秒..." -ForegroundColor Yellow

# 等待事件（60 秒超时）
$event = Wait-Event -SourceIdentifier 'MonitorNotepad' -Timeout 60

if ($event) {
    $proc = $event.SourceEventArgs.NewEvent.TargetInstance
    Write-Host "`n[检测到新进程]" -ForegroundColor Cyan
    Write-Host "  进程名: $($proc.Name)"
    Write-Host "  PID: $($proc.ProcessId)"
    Write-Host "  命令行: $($proc.CommandLine)"
    Write-Host "  创建时间: $(Get-Date -Format 'HH:mm:ss')"
    $event | Remove-Event
} else {
    Write-Host "`n60 秒内未检测到 notepad.exe 启动" -ForegroundColor DarkGray
}

# 清理事件订阅
Get-EventSubscriber -SourceIdentifier 'MonitorNotepad' -ErrorAction SilentlyContinue |
    Unregister-Event
Remove-Job -Name 'MonitorNotepad' -Force -ErrorAction SilentlyContinue

# ---- 场景 2：远程 CIM 会话管理 ----

# 创建到多台主机的 CIM 会话（使用当前凭据）
$computers = @('SRV-DB01', 'SRV-WEB01', 'SRV-FILE01')

$sessions = $computers | ForEach-Object {
    $session = $null
    try {
        $session = New-CimSession -ComputerName $_ -ErrorAction Stop
        Write-Host "[OK] 已连接: $_" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] 连接失败: $_ - $($_.Exception.Message)" -ForegroundColor Red
    }
    $session
} | Where-Object { $_ -ne $null }

# 批量查询磁盘空间
$sessions | ForEach-Object {
    $computer = $_.ComputerName
    Get-CimInstance -CimSession $_ -Query `
        "SELECT DeviceID, Size, FreeSpace FROM Win32_LogicalDisk WHERE DriveType=3" |
        ForEach-Object {
            [PSCustomObject]@{
                Server   = $computer
                Drive    = $_.DeviceID
                TotalGB  = [math]::Round($_.Size/1GB, 2)
                FreeGB   = [math]::Round($_.FreeSpace/1GB, 2)
                UsedPct  = [math]::Round(($_.Size - $_.FreeSpace)/$_.Size*100, 1)
            }
        }
} | Format-Table -AutoSize

# 批量查询服务状态
$serviceName = 'WinRM'
$sessions | ForEach-Object {
    Get-CimInstance -CimSession $_ -Query `
        "SELECT State, StartMode FROM Win32_Service WHERE Name='$serviceName'" |
        ForEach-Object {
            [PSCustomObject]@{
                Server = $_PSItem.PSComputerName
                Service = $serviceName
                State  = $_.State
                Start  = $_.StartMode
            }
        }
} | Format-Table -AutoSize

# 清理会话
$sessions | Remove-CimSession
Write-Host "`n已清理所有 CIM 会话" -ForegroundColor Green

# ---- 场景 3：文件变更实时监控 ----

# 监控指定目录下的文件创建事件（利用 CIM 的 __InstanceCreationEvent）
$watchPath = 'C:\Temp\Watch'
if (-not (Test-Path $watchPath)) { New-Item -Path $watchPath -ItemType Directory | Out-Null }

# 使用 .NET FileSystemWatcher 作为轻量替代（CIM 事件开销较大）
$watcher = [System.IO.FileSystemWatcher]::new($watchPath)
$watcher.Filter = '*.*'
$watcher.EnableRaisingEvents = $true

# 注册文件创建事件
$action = {
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    $time = $Event.TimeGenerated.ToString('HH:mm:ss.fff')
    Write-Host "[$time] $changeType : $name" -ForegroundColor Yellow
}

Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action |
    Out-Null

Write-Host "正在监控目录: $watchPath" -ForegroundColor Green
Write-Host "创建文件触发事件，30 秒后自动停止..." -ForegroundColor Yellow

Start-Sleep -Seconds 30

# 清理
$watcher.EnableRaisingEvents = $false
Get-EventSubscriber | Unregister-Event
Get-Job | Remove-Job -Force
```

执行结果示例：

```
已注册 notepad.exe 进程监控事件...
请打开记事本触发事件，等待 60 秒...

[检测到新进程]
  进程名: notepad.exe
  PID: 28456
  命令行: "C:\Windows\System32\notepad.exe" C:\Temp\test.txt
  创建时间: 14:23:17

[OK] 已连接: SRV-DB01
[OK] 已连接: SRV-WEB01
[FAIL] 连接失败: SRV-FILE01 - The RPC server is unavailable.

Server   Drive TotalGB  FreeGB UsedPct
------   ----- -------  ------ -------
SRV-DB01 C:     256.00   45.30   82.3
SRV-DB01 D:    1024.00  312.50   69.5
SRV-WEB01 C:     128.00   89.20   30.3

Server   Service State  Start
------   ------- -----  -----
SRV-DB01 WinRM   Running Auto
SRV-WEB01 WinRM   Running Auto

已清理所有 CIM 会话

正在监控目录: C:\Temp\Watch
创建文件触发事件，30 秒后自动停止...
[14:25:03.127] Created : report.csv
[14:25:08.342] Created : config.json
[14:25:15.891] Created : backup.zip
```

第一个场景展示了 CIM 事件订阅的核心模式：通过 `Register-CimIndicationEvent` 注册一个后台事件查询任务，WMI 服务每秒（WITHIN 1）检查一次是否有新的 `notepad.exe` 进程出现，事件触发后通过 `Wait-Event` 接收详细信息。这种模式可以扩展到监控服务停止、磁盘空间低于阈值等运维告警场景。

第二个场景演示了 `CimSession` 的批量远程管理能力。与每次调用 `Get-CimInstance -ComputerName` 不同，CimSession 会建立持久的连接通道，后续的多个查询复用同一会话，避免了反复认证和连接建立的开销。在管理大量服务器时，这种方式的效率提升非常明显。

第三个场景中，鉴于 CIM 文件监控事件在系统开销上较重，代码也演示了使用 .NET 的 `FileSystemWatcher` 作为轻量级替代方案，这在实际生产中更为实用。

## 注意事项

1. **优先使用 Get-CimInstance 而非 Get-WmiObject**：`Get-WmiObject` 在 PowerShell 3.0 后已被标记为过时，`Get-CimInstance` 使用标准 WS-Man 协议，跨平台兼容性更好，且返回的对象更符合 PowerShell 管道规范。

2. **WQL 过滤优于 Where-Object 过滤**：通过 WQL 的 WHERE 子句或 `-Filter` 参数在服务端完成数据筛选，避免将全量数据传输到客户端再过滤，在查询远程主机时性能差距尤为明显。

3. **Win32_Product 类的查询陷阱**：`Win32_Product` 在枚举时会触发每个 MSI 包的完整性检查，非常耗时且可能引发 Windows Installer 重新配置。生产环境中采集软件清单应改用注册表路径读取。

4. **CIM 事件订阅的资源开销**：`WITHIN` 子句指定的轮询间隔不宜过短，频繁轮询会增加 CPU 和 WMI 服务的负担。一般建议设置为 5 秒以上。对于高频事件监控，优先考虑 .NET 的 `FileSystemWatcher` 或 `System.Diagnostics.TraceEvent` 等原生 API。

5. **远程 CIM 连接的防火墙配置**：CIM 远程管理依赖 WinRM 服务（端口 5985/5986）。目标主机必须启用 WinRM（`Enable-PSRemoting -Force`），防火墙放行对应端口，且两端的信任主机配置需匹配（`Set-Item WSMan:\localhost\Client\TrustedHosts`）。

6. **CIM 类名在不同系统上的差异**：部分 CIM 类（如 `Win32_PhysicalMemory`）在不同 Windows 版本上返回的属性可能不同。建议在正式脚本中先用 `Get-CimClass` 检查目标类是否存在及其属性列表，避免因属性缺失导致脚本异常退出。
