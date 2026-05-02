---
layout: post
date: 2025-05-13 08:00:00
updated: 2025-05-13 08:00:00
title: "PowerShell 技能连载 - 事件日志与系统监控"
description: PowerTip of the Day - Event Logs and System Monitoring in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- event-log
- monitoring
- system-administration
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

Windows 事件日志是故障排查的"黑匣子"——系统崩溃、应用异常、安全审计、服务启停，几乎所有重要事件都会被记录到事件日志中。对于运维人员来说，能够高效地查询、筛选和分析事件日志是一项必备技能。PowerShell 提供了 `Get-WinEvent` 命令，其过滤能力远超传统的事件查看器 GUI。

本文将讲解事件日志的查询技巧、自动化监控脚本、性能计数器采集，以及如何构建系统健康检查工具。

<!-- more -->

## 事件日志基础查询

`Get-WinEvent` 是查询事件日志的主力命令，替代了旧版 `Get-EventLog`：

```powershell
# 列出所有可用的日志
Get-WinEvent -ListLog * | Where-Object RecordCount -gt 0 |
    Select-Object LogName, RecordCount, FileSize,
        @{N='大小MB'; E={[math]::Round($_.FileSize/1MB, 2)}} |
    Sort-Object RecordCount -Descending |
    Select-Object -First 15 |
    Format-Table -AutoSize

# 查询最近的系统日志
Get-WinEvent -LogName System -MaxEvents 10 |
    Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Format-List

# 查询特定事件 ID
Get-WinEvent -LogName System | Where-Object Id -eq 7036 |
    Select-Object -First 5 TimeCreated, Message
```

执行结果示例：

```
LogName                   RecordCount   大小MB
-------                   -----------   ------
Security                      245812    128.45
Application                    87432     42.18
System                         45678     18.92
Microsoft-Windows-PowerShell   12345      5.67

TimeCreated          Id LevelDisplayName Message
-----------          -- ---------------- -------
2025-05-13 08:30:15 7036 信息             服务控制管理器...
2025-05-13 08:30:12 7040 信息             服务控制管理器...
2025-05-13 08:28:45  100 信息             Windows Update...

TimeCreated          Message
-----------          -------
2025-05-13 08:15:00 服务 Windows Update 已进入运行状态
2025-05-13 08:00:00 服务 WinRM 已进入运行状态
```

## 使用 FilterHashtable 高效过滤

`Get-WinEvent` 的 `FilterHashtable` 参数可以将过滤条件推送到事件日志引擎，比管道 `Where-Object` 快数倍：

```powershell
# 按时间范围过滤（最近 1 小时的错误和警告）
$oneHourAgo = (Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    Level     = 1, 2, 3
    StartTime = $oneHourAgo
} | Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Format-Table -AutoSize -Wrap

# 按事件 ID 列表过滤
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id      = 41, 1074, 6008
} -MaxEvents 20 | Select-Object TimeCreated, Id, Message

# 按提供者（来源）过滤
Get-WinEvent -FilterHashtable @{
    LogName    = 'Application'
    ProviderName = 'Application Error'
    StartTime  = (Get-Date).AddDays(-7)
} | Select-Object TimeCreated, Id,
    @{N='应用程序'; E={$_.Properties[0].Value}},
    @{N='版本'; E={$_.Properties[1].Value}} |
    Format-Table -AutoSize

# 按关键词过滤（安全审计）
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id      = 4624, 4625
    StartTime = (Get-Date).AddHours(-24)
} | Select-Object TimeCreated, Id,
    @{N='用户'; E={$_.Properties[5].Value}},
    @{N='来源IP'; E={$_.Properties[18].Value}} |
    Format-Table -AutoSize
```

执行结果示例：

```
TimeCreated          Id  LevelDisplayName Message
-----------          --  ---------------- -------
2025-05-13 08:25:31 1014 警告             DNS 解析超时
2025-05-13 08:20:15 1001 错误             Windows 错误报告
2025-05-13 08:15:42  702 警告             服务启动失败

TimeCreated          Id  应用程序               版本
-----------          --  --------               ----
2025-05-13 02:15:00 1000 chrome.exe           124.0.6367
2025-05-12 18:30:22 1000 Outlook.exe          16.0.17928

TimeCreated          Id  用户                来源IP
-----------          --  ----                ------
2025-05-13 08:30:01 4624 CONTOSO\admin      192.168.1.100
2025-05-13 07:15:22 4625 unknown_user       10.0.0.55
```

> **注意**：`Level` 值的含义：1 = Critical，2 = Error，3 = Warning，4 = Information，5 = Verbose。

## 构建自动化监控脚本

以下是一个实用的系统健康监控脚本，可以定时运行并生成报告：

```powershell
function Get-SystemHealthReport {
    <#
    .SYNOPSIS
    生成系统健康状态报告
    #>
    [CmdletBinding()]
    param(
        [int]$CriticalEventHours = 1,
        [int]$DiskWarningThreshold = 80,
        [int]$CPUWarningThreshold = 85
    )

    $report = [ordered]@{}
    $report['生成时间'] = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $report['计算机名'] = $env:COMPUTERNAME

    # 1. 检查关键事件
    $startTime = (Get-Date).AddHours(-$CriticalEventHours)
    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName   = 'System', 'Application'
        Level     = 1, 2
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $report['关键事件数'] = $criticalEvents.Count
    $report['关键事件'] = $criticalEvents |
        Select-Object TimeCreated, LogName, Id, LevelDisplayName,
            @{N='消息摘要'; E={$_.Message.Substring(0, [Math]::Min(80, $_.Message.Length))}} |
        Format-Table -AutoSize

    # 2. 检查磁盘空间
    $diskStatus = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $usedPct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
            [PSCustomObject]@{
                驱动器 = $_.DeviceID
                已用%  = $usedPct
                可用GB = [math]::Round($_.FreeSpace / 1GB, 2)
                状态   = if ($usedPct -gt $DiskWarningThreshold) { 'WARNING' } else { 'OK' }
            }
        }
    $report['磁盘状态'] = $diskStatus | Format-Table -AutoSize

    # 3. 检查自动重启的服务
    $autoRestartServices = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Id      = 7036, 7045
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue |
        Select-Object TimeCreated,
            @{N='服务'; E={if ($_.Message -match '(.+?) 服务') {$Matches[1]} else {$_.Message}}} |
        Group-Object 服务 |
        Where-Object Count -gt 3 |
        Select-Object Name, Count

    $report['频繁重启服务'] = if ($autoRestartServices) {
        $autoRestartServices | Format-Table -AutoSize
    } else {
        "无异常"
    }

    # 4. 检查 Windows 更新状态
    $lastUpdate = Get-CimInstance Win32_QuickFixEngineering |
        Sort-Object InstalledOn -Descending | Select-Object -First 1
    $report['最新补丁'] = "$($lastUpdate.HotFixID) ($($lastUpdate.InstalledOn.ToString('yyyy-MM-dd')))"

    # 5. 系统运行时间
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    $report['运行时间'] = "$($uptime.Days) 天 $($uptime.Hours) 小时"

    # 输出报告
    foreach ($key in $report.Keys) {
        if ($report[$key] -is [string]) {
            Write-Host "${key}: $($report[$key])"
        } else {
            Write-Host "`n${key}:" -ForegroundColor Cyan
            $report[$key]
        }
    }
}

Get-SystemHealthReport
```

执行结果示例：

```
生成时间: 2025-05-13 08:30:00
计算机名: DESKTOP-WORK01

关键事件数: 3

TimeCreated          LogName     Id LevelDisplayName 消息摘要
-----------          -------     -- ---------------- --------
2025-05-13 08:25:31  System     1014 警告             DNS 解析超时: api.example.com
2025-05-13 08:20:15  Application 1001 错误            应用程序错误: chrome.exe

磁盘状态:
驱动器 已用% 可用GB 状态
------ ----- ------ ----
C:     59.8  191.58 OK
D:     68.9  289.33 OK

频繁重启服务: 无异常
最新补丁: KB5036908 (2025-05-10)
运行时间: 9 天 4 小时
```

## 性能计数器采集

除了事件日志，Windows 性能计数器是监控系统资源使用情况的另一重要数据源：

```powershell
# 查看可用的性能计数器类别
Get-Counter -ListSet * | Select-Object CounterSetName, Description |
    Where-Object CounterSetName -match 'Processor|Memory|Disk|Network' |
    Format-Table -AutoSize

# 采集关键性能指标
$counters = @(
    '\Processor(_Total)\% Processor Time'
    '\Memory\Available MBytes'
    '\Memory\% Committed Bytes In Use'
    '\PhysicalDisk(_Total)\Disk Read Bytes/sec'
    '\PhysicalDisk(_Total)\Disk Write Bytes/sec'
    '\Network Interface(*)\Bytes Total/sec'
)

# 采集一次
$sample = Get-Counter -Counter $counters
$sample.CounterSamples | ForEach-Object {
    [PSCustomObject]@{
        计数器 = $_.Path -replace '^\\\\[^\\]+\\', ''
        值     = [math]::Round($_.CookedValue, 2)
    }
} | Format-Table -AutoSize

# 持续采集（每 5 秒采样，共 12 次 = 1 分钟）
$results = Get-Counter -Counter '\Processor(_Total)\% Processor Time' `
    -SampleInterval 5 -MaxSamples 12

$results.CounterSamples | ForEach-Object {
    [PSCustomObject]@{
        时间    = $_.Timestamp.ToString('HH:mm:ss')
        CPU使用率 = [math]::Round($_.CookedValue, 1)
    }
} | Format-Table -AutoSize

# 计算平均值
$avgCpu = ($results.CounterSamples.CookedValue | Measure-Object -Average).Average
Write-Host "1 分钟平均 CPU 使用率：$([math]::Round($avgCpu, 1))%" -ForegroundColor Cyan
```

执行结果示例：

```
CounterSetName                 Description
---------------                 -----------
Processor                       处理器性能计数器
Memory                          内存使用情况计数器
PhysicalDisk                    物理磁盘性能计数器
Network Interface               网络接口性能计数器

计数器                                      值
------                                      --
Processor(_Total)\% Processor Time         12.45
Memory\Available MBytes                   8456.00
Memory\% Committed Bytes In Use            65.32
PhysicalDisk(_Total)\Disk Read Bytes/sec  524288.00
PhysicalDisk(_Total)\Disk Write Bytes/sec 262144.00

时间     CPU使用率
----     --------
08:30:00 15.2
08:30:05 22.8
08:30:10 18.5
...
08:30:55 14.3

1 分钟平均 CPU 使用率：17.6%
```

## 实时事件监控

通过 `Register-WmiEvent` 或 `Register-CimIndicationEvent`，可以对特定事件进行实时监控并触发操作：

```powershell
# 监控新事件的创建
$query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_NTLogEvent' AND TargetInstance.LogFile = 'System' AND TargetInstance.EventType <= 2"

Register-WmiEvent -Query $query -SourceIdentifier "SystemErrorMonitor" -Action {
    $event = $Event.SourceEventArgs.NewEvent.TargetInstance
    $body = @"
时间: $($event.TimeGenerated)
事件ID: $($event.EventCode)
类别: $($event.CategoryString)
消息: $($event.Message.Substring(0, [Math]::Min(200, $event.Message.Length)))
"@

    # 记录到日志文件
    Add-Content -Path "C:\Logs\critical-events.log" -Value $body

    # 可以在此处添加邮件通知或 Webhook
    Write-Host "检测到关键事件：ID $($event.EventCode)" -ForegroundColor Red
}

# 查看已注册的事件订阅
Get-EventSubscriber

# 手动触发检查
Get-Event -SourceIdentifier "SystemErrorMonitor"

# 取消订阅
Unregister-Event -SourceIdentifier "SystemErrorMonitor"
```

执行结果示例：

```
SubscriptionId   Name                 Enabled
--------------   ----                 -------
1                SystemErrorMonitor      True

检测到关键事件：ID 1001
```

## 注意事项

1. **FilterHashtable 优先**：始终使用 `-FilterHashtable` 而非管道 `Where-Object` 过滤，前者在日志引擎层面过滤，性能提升可达 10-100 倍
2. **日志大小管理**：定期检查和归档事件日志，避免日志文件过大导致查询变慢。可通过组策略配置日志大小上限和覆盖策略
3. **安全日志权限**：查询安全日志（`Security`）需要管理员权限
4. **性能计数器开销**：频繁采集性能计数器会消耗 CPU 资源，建议采样间隔不低于 5 秒
5. **远程查询**：`Get-WinEvent` 支持 `-ComputerName` 参数远程查询，但需要 WinRM 或 RPC 连接
6. **事件消息截断**：某些事件消息很长，使用 `$_.Message.Substring(0, N)` 截取前 N 个字符用于显示
