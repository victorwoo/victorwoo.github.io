---
layout: post
date: 2025-04-22 08:00:00
updated: 2025-04-22 08:00:00
title: "PowerShell 技能连载 - 系统性能监控实战"
description: PowerTip of the Day - System Performance Monitoring with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- monitoring
- performance
- devops
---

_适用于 PowerShell 7.0 及以上版本_

在服务器运维和 DevOps 实践中，系统性能监控是保障业务稳定运行的基石。无论是排查突发的性能抖动，还是进行容量规划和趋势分析，都需要一套可靠的监控手段。传统的 GUI 工具（如任务管理器、perfmon）虽然直观，但不适合自动化场景和大规模服务器管理。

PowerShell 提供了对 WMI/CIM 类、.NET 性能计数器和系统 API 的完整访问能力，让我们可以用脚本化的方式采集、分析和导出系统性能数据。本文将介绍如何使用 PowerShell 构建一套实用的系统性能监控方案，涵盖 CPU、内存、磁盘、进程、网络等关键指标。

## 采集 CPU、内存和磁盘基础指标

系统监控的第一步是获取核心资源的使用情况。通过 CIM 类可以高效地采集 CPU 利用率、内存使用率和磁盘空间信息，这些是判断系统健康状态最基本的指标。

下面的函数将 CPU、内存和磁盘三项指标整合到一个对象中，方便后续统一处理和比较：

```powershell
function Get-SystemPerformanceSnapshot {
    <#
    .SYNOPSIS
    获取系统核心性能指标的快照
    #>
    $cpu = Get-CimInstance -ClassName Win32_Processor |
        Measure-Object -Property LoadPercentage -Average |
        Select-Object -ExpandProperty Average

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMemoryGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMemoryPct = [math]::Round(
        ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) /
        $os.TotalVisibleMemorySize * 100, 1
    )

    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $freeGB  = [math]::Round($_.FreeSpace / 1GB, 2)
            $totalGB = [math]::Round($_.Size / 1GB, 2)
            $usedPct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
            [PSCustomObject]@{
                Drive    = $_.DeviceID
                TotalGB  = $totalGB
                FreeGB   = $freeGB
                UsedPct  = $usedPct
            }
        }

    [PSCustomObject]@{
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        CpuUsagePct   = $cpu
        TotalMemoryGB = $totalMemoryGB
        FreeMemoryGB  = $freeMemoryGB
        MemoryUsedPct = $usedMemoryPct
        Disks         = $disks
    }
}

Get-SystemPerformanceSnapshot
```

执行结果示例：

```
Timestamp     : 2025-04-22 09:15:30
CpuUsagePct   : 23
TotalMemoryGB : 31.89
FreeMemoryGB  : 14.52
MemoryUsedPct : 54.5
Disks         : {@{Drive=C:; TotalGB=476.68; FreeGB=218.35; UsedPct=54.2},
               @{Drive=D:; TotalGB=931.51; FreeGB=612.08; UsedPct=34.3}}
```

可以看到，一条命令就能拿到系统当前的核心资源状态。当 CPU 或内存使用率超过阈值时，运维人员可以第一时间感知并介入。

## 进程监控与资源排行

系统性能异常往往由个别进程引起。通过分析进程的资源占用情况，可以快速定位问题根源——是内存泄漏、CPU 密集计算，还是磁盘 I/O 瓶颈。

下面这段脚本按 CPU 和内存占用分别列出 Top N 进程，并标记出超出阈值的高消耗进程：

```powershell
function Get-TopProcesses {
    <#
    .SYNOPSIS
    获取资源占用最高的进程列表
    .PARAMETER Top
    返回的进程数量，默认 10
    .PARAMETER CpuThreshold
    CPU 使用率告警阈值（百分比），默认 80
    .PARAMETER MemThresholdMB
    内存占用告警阈值（MB），默认 500
    #>
    param(
        [int]$Top = 10,
        [double]$CpuThreshold = 80,
        [double]$MemThresholdMB = 500
    )

    $processes = Get-Process | Where-Object { $_.Id -gt 0 } |
        Select-Object Id, ProcessName,
            @{N='CPU_Sec';    E={[math]::Round($_.CPU, 2)}},
            @{N='Memory_MB';  E={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
            @{N='Threads';    E={$_.Threads.Count}},
            StartTime

    $byCpu = $processes | Sort-Object CPU_Sec -Descending | Select-Object -First $Top
    $byMem = $processes | Sort-Object Memory_MB -Descending | Select-Object -First $Top

    $alerts = $processes | Where-Object {
        $_.CPU_Sec -gt $CpuThreshold -or $_.Memory_MB -gt $MemThresholdMB
    }

    [PSCustomObject]@{
        TopByCpu  = $byCpu
        TopByMem  = $byMem
        Alerts    = $alerts
    }
}

$result = Get-TopProcesses -Top 5
$result.TopByCpu | Format-Table -AutoSize
```

执行结果示例：

```
 Id ProcessName CPU_Sec Memory_MB Threads StartTime
 -- ----------- ------- --------- ------- ---------
4212 chrome        312.45   892.31      38 4/22/2025 8:30:12
3088 devenv       187.20   645.80      27 4/22/2025 8:15:05
1524 postgres     145.67   412.55      16 4/22/2025 7:00:00
 892 dwm          120.33   210.40      12 4/22/2025 6:58:01
1024 powershell    98.12   156.70       8 4/22/2025 9:10:30
```

在日常运维中，将此脚本放入定时任务，每隔几分钟运行一次，就能持续跟踪进程资源变化趋势。当某个进程突然飙升至告警阈值之上，可以及时触发通知。

## 网络连接统计与异常检测

网络连接状态是排查服务可用性和安全事件的重要依据。大量 TIME_WAIT 连接可能意味着短连接风暴，异常的外连 IP 可能暗示安全风险，某个端口连接数暴涨可能表示正在遭受攻击或业务流量激增。

以下脚本通过 `Get-NetTCPConnection` 统计连接状态分布和端口连接数，帮助快速发现网络层面的异常：

```powershell
function Get-NetworkConnectionStats {
    <#
    .SYNOPSIS
    统计本机 TCP 连接状态和端口分布
    #>
    $connections = Get-NetTCPConnection |
        Where-Object { $_.State -ne 'Bound' }

    # 按连接状态分组统计
    $stateStats = $connections |
        Group-Object State |
        Sort-Object Count -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                State = $_.Name
                Count = $_.Count
            }
        }

    # 按本地监听端口分组统计
    $portStats = $connections |
        Where-Object { $_.LocalPort -gt 0 } |
        Group-Object LocalPort |
        Sort-Object Count -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [PSCustomObject]@{
                Port  = $_.Name
                Count = $_.Count
            }
        }

    # 统计远端 IP 连接数（排查异常外连）
    $remoteIps = $connections |
        Where-Object { $_.RemoteAddress -and $_.RemoteAddress -ne '0.0.0.0' -and $_.RemoteAddress -ne '::' } |
        Group-Object RemoteAddress |
        Sort-Object Count -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            [PSCustomObject]@{
                RemoteIP = $_.Name
                Count    = $_.Count
            }
        }

    [PSCustomObject]@{
        ConnectionStates = $stateStats
        TopPorts         = $portStats
        TopRemoteIps     = $remoteIps
        TotalConnections = $connections.Count
    }
}

$stats = Get-NetworkConnectionStats
$stats.ConnectionStates | Format-Table -AutoSize
```

执行结果示例：

```
State       Count
-----       -----
Established   142
TimeWait       89
CloseWait      23
Listen         18
SynSent         5
```

当 TIME_WAIT 或 CLOSE_WAIT 连接数异常增多时，往往意味着应用层的连接管理存在问题。结合远端 IP 统计，还能识别出是否存在异常的频繁外连行为。

## 数据导出为 CSV 和 JSON

监控数据如果不能持久化存储，就只能在当下查看，无法做历史趋势分析。将采集到的性能数据导出为 CSV 或 JSON 格式，既方便导入 Excel 做图表，也便于与 Grafana、ELK 等监控平台集成。

下面这段代码展示了如何将性能快照追加写入 CSV 文件，以及一次性导出为结构化的 JSON：

```powershell
function Export-PerformanceData {
    <#
    .SYNOPSIS
    将性能数据导出为 CSV 和 JSON 格式
    .PARAMETER OutputDir
    输出目录路径
    #>
    param(
        [string]$OutputDir = "$HOME\PerfLogs"
    )

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $snapshot = Get-SystemPerformanceSnapshot
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # 扁平化磁盘数据，便于 CSV 追加
    $flatData = [PSCustomObject]@{
        Timestamp     = $snapshot.Timestamp
        CpuUsagePct   = $snapshot.CpuUsagePct
        MemoryUsedPct = $snapshot.MemoryUsedPct
        FreeMemoryGB  = $snapshot.FreeMemoryGB
        DiskInfo      = ($snapshot.Disks | ForEach-Object {
            "$($_.Drive)=$($_.UsedPct)%"
        }) -join '; '
    }

    # 追加写入 CSV（适合长期采集）
    $csvPath = Join-Path $OutputDir "perf_$(Get-Date -Format 'yyyyMMdd').csv"
    $flatData | Export-Csv -Path $csvPath -NoTypeInformation -Append

    # 完整快照导出 JSON（适合单次详细记录）
    $jsonPath = Join-Path $OutputDir "perf_$timestamp.json"
    $snapshot | ConvertTo-Json -Depth 3 | Set-Content -Path $jsonPath

    [PSCustomObject]@{
        CsvFile  = $csvPath
        JsonFile = $jsonPath
        Written  = $true
    }
}

Export-PerformanceData
```

执行结果示例：

```
CsvFile  : /home/user/PerfLogs/perf_20250422.csv
JsonFile : /home/user/PerfLogs/perf_20250422_091530.json
Written  : True
```

CSV 追加模式让每次采集的行数据逐行写入同一个文件，配合 Excel 或 Python 脚本即可绘制性能趋势曲线。JSON 格式则保留了完整的嵌套结构，适合程序化消费。

## 持续监控与阈值告警

单次采集只能看到瞬时状态，真正的运维监控需要持续轮询并在指标异常时主动告警。下面这段脚本实现了一个轻量级的持续监控循环，支持 CPU、内存、磁盘三个维度的阈值检测，并在超限时输出告警信息。

你可以将告警逻辑替换为发送邮件、调用 Webhook 或写入事件日志，实现完整的告警链路：

```powershell
function Start-PerformanceWatch {
    <#
    .SYNOPSIS
    持续监控系统性能并在超阈值时告警
    .PARAMETER IntervalSeconds
    采集间隔（秒），默认 30
    .PARAMETER CpuThreshold
    CPU 使用率告警阈值，默认 85
    .PARAMETER MemThreshold
    内存使用率告警阈值，默认 90
    .PARAMETER DiskThreshold
    磁盘使用率告警阈值，默认 90
    .PARAMETER DurationMinutes
    监控持续时间（分钟），默认 10
    #>
    param(
        [int]$IntervalSeconds = 30,
        [double]$CpuThreshold = 85,
        [double]$MemThreshold = 90,
        [double]$DiskThreshold = 90,
        [int]$DurationMinutes = 10
    )

    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    $alertCount = 0

    Write-Host "性能监控已启动，持续 $DurationMinutes 分钟，间隔 ${IntervalSeconds}s" `
        -ForegroundColor Cyan
    Write-Host ("CPU>{0}% | MEM>{1}% | DISK>{2}% 触发告警`n" -f `
        $CpuThreshold, $MemThreshold, $DiskThreshold) -ForegroundColor DarkGray

    while ((Get-Date) -lt $endTime) {
        $snap = Get-SystemPerformanceSnapshot
        $alerts = @()

        if ($snap.CpuUsagePct -gt $CpuThreshold) {
            $alerts += "CPU 使用率 $($snap.CpuUsagePct)% 超过阈值 ${CpuThreshold}%"
        }
        if ($snap.MemoryUsedPct -gt $MemThreshold) {
            $alerts += "内存使用率 $($snap.MemoryUsedPct)% 超过阈值 ${MemThreshold}%"
        }
        foreach ($disk in $snap.Disks) {
            if ($disk.UsedPct -gt $DiskThreshold) {
                $alerts += "磁盘 $($disk.Drive) 使用率 $($disk.UsedPct)% 超过阈值 ${DiskThreshold}%"
            }
        }

        $timeStr = Get-Date -Format "HH:mm:ss"
        if ($alerts.Count -gt 0) {
            $alertCount += $alerts.Count
            Write-Host "[$timeStr] ALERT:" -ForegroundColor Red -NoNewline
            Write-Host " $($alerts -join ' | ')" -ForegroundColor Yellow
        } else {
            Write-Host "[$timeStr] OK - CPU:$($snap.CpuUsagePct)% MEM:$($snap.MemoryUsedPct)%" `
                -ForegroundColor Green
        }

        Start-Sleep -Seconds $IntervalSeconds
    }

    Write-Host "`n监控结束，共触发 $alertCount 条告警。" -ForegroundColor Cyan
}

Start-PerformanceWatch -IntervalSeconds 15 -DurationMinutes 2
```

执行结果示例：

```
性能监控已启动，持续 2 分钟，间隔 15s
CPU>85% | MEM>90% | DISK>90% 触发告警

[09:15:00] OK - CPU:23% MEM:54.5%
[09:15:15] OK - CPU:28% MEM:55.1%
[09:15:30] ALERT: CPU 使用率 92% 超过阈值 85%
[09:15:45] OK - CPU:31% MEM:56.2%
[09:16:00] OK - CPU:25% MEM:54.8%
[09:16:15] OK - CPU:22% MEM:53.9%
[09:16:30] OK - CPU:27% MEM:55.5%
[09:16:45] OK - CPU:24% MEM:54.2%

监控结束，共触发 1 条告警。
```

在实际生产环境中，可以将此脚本作为 Windows 计划任务或 systemd 服务运行，配合邮件通知模块（`Send-MailMessage`）或 Webhook（`Invoke-RestMethod`）将告警推送到运维群。

## 注意事项

1. **CIM vs WMI**：优先使用 `Get-CimInstance` 而非已弃用的 `Get-WmiObject`，CIM 支持远程会话复用，性能更好
2. **采集频率**：间隔不宜过短（建议不低于 10 秒），频繁采集本身会消耗 CPU，尤其在旧设备上
3. **远程监控**：结合 PowerShell Remoting，可以在一台管理机上统一采集多台服务器的性能数据，使用 `-ComputerName` 参数即可
4. **权限要求**：部分 CIM 类和性能计数器需要管理员权限才能访问，脚本应以提升权限运行
5. **数据保留**：CSV 追加模式下注意定期归档和清理旧文件，避免单个文件过大影响读取性能
6. **跨平台差异**：PowerShell 7 在 Linux/macOS 上部分 CIM 类不可用，需使用 `/proc` 文件系统或 `Get-Process` 等替代方案
