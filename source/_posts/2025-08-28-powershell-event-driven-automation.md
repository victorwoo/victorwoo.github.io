---
layout: post
date: 2025-08-28 08:00:00
updated: 2025-08-28 08:00:00
title: "PowerShell 技能连载 - 事件驱动自动化"
description: PowerTip of the Day - Event-Driven Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- events
- automation
- event-handling
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

传统的自动化脚本是"拉模型"——定时轮询检查状态再执行操作。事件驱动是"推模型"——当特定事件发生时自动触发处理逻辑。Windows 和 PowerShell 提供了丰富的事件机制：WMI 事件、.NET 对象事件、文件系统变更事件、Windows 事件日志事件。掌握事件驱动编程，可以构建响应迅速、资源高效的自动化系统。

本文将讲解 PowerShell 中的事件驱动模式及其在运维自动化中的应用。

<!-- more -->

## WMI 事件订阅

```powershell
# 监控进程创建事件
$query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"

Register-WmiEvent -Query $query -SourceIdentifier "ProcessCreated" -Action {
    $proc = $Event.SourceEventArgs.NewEvent.TargetInstance
    $name = $proc.Name
    $pid = $proc.ProcessId
    $time = Get-Date -Format 'HH:mm:ss'

    Write-Host "[$time] 新进程：$name (PID: $pid)" -ForegroundColor Green

    if ($name -in @("cmd.exe", "powershell.exe", "pwsh.exe")) {
        Write-Host "  警告：检测到命令行进程启动" -ForegroundColor Yellow
    }
}

Write-Host "已订阅进程创建事件" -ForegroundColor Cyan
Write-Host "打开新的命令行窗口测试..." -ForegroundColor DarkGray

# 监控服务状态变更
$serviceQuery = "SELECT * FROM __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_Service' AND TargetInstance.State <> PreviousInstance.State"

Register-WmiEvent -Query $serviceQuery -SourceIdentifier "ServiceStateChanged" -Action {
    $svc = $Event.SourceEventArgs.NewEvent.TargetInstance
    $prev = $Event.SourceEventArgs.NewEvent.PreviousInstance
    $name = $svc.Name
    $newState = $svc.State
    $oldState = $prev.State

    $color = if ($newState -eq 'Running') { 'Green' } else { 'Red' }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 服务变更：$name $oldState => $newState" -ForegroundColor $color
}

Write-Host "已订阅服务状态变更事件" -ForegroundColor Cyan

# 清理事件订阅
# Get-EventSubscriber | Unregister-Event
# Get-Job | Where-Object { $_.Name -match 'ProcessCreated|ServiceStateChanged' } | Remove-Job
```

执行结果示例：

```
已订阅进程创建事件
打开新的命令行窗口测试...
[08:30:15] 新进程：cmd.exe (PID: 12345)
  警告：检测到命令行进程启动
[08:30:45] 新进程：notepad.exe (PID: 12346)
已订阅服务状态变更事件
[08:31:10] 服务变更：Spooler Running => Stopped
```

## 文件到达自动处理

```powershell
# 监控文件到达并自动处理
function Start-FileArrivalProcessor {
    param(
        [string]$WatchPath = "C:\DropZone",
        [string]$ProcessedPath = "C:\DropZone\Processed",
        [string]$ErrorPath = "C:\DropZone\Errors"
    )

    foreach ($path in @($WatchPath, $ProcessedPath, $ErrorPath)) {
        New-Item $path -ItemType Directory -Force | Out-Null
    }

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WatchPath
    $watcher.Filter = "*.csv"
    $watcher.EnableRaisingEvents = $true

    $action = {
        $filePath = $Event.SourceEventArgs.FullPath
        $fileName = $Event.SourceEventArgs.Name

        Start-Sleep -Seconds 2

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 检测到新文件：$fileName" -ForegroundColor Cyan

        try {
            $data = Import-Csv $filePath -Encoding UTF8
            $rows = $data.Count
            Write-Host "  数据行数：$rows" -ForegroundColor Green

            $destPath = Join-Path $ProcessedPath $fileName
            Move-Item $filePath $destPath -Force
            Write-Host "  已移至处理目录" -ForegroundColor Green
        } catch {
            $errorDest = Join-Path $ErrorPath $fileName
            Move-Item $filePath $errorDest -Force
            Write-Host "  处理失败：$($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier "FileArrival"

    Write-Host "文件到达处理器已启动：$WatchPath" -ForegroundColor Green
}

Start-FileArrivalProcessor
```

执行结果示例：

```
文件到达处理器已启动：C:\DropZone
[08:35:10] 检测到新文件：orders-20250828.csv
  数据行数：150
  已移至处理目录
```

## 定时事件与调度

```powershell
# 使用 Timer 对象创建定时任务
function Start-PeriodicCheck {
    param(
        [scriptblock]$CheckScript,
        [int]$IntervalSeconds = 60,
        [string]$Name = "PeriodicCheck"
    )

    $timer = New-Object System.Timers.Timer
    $timer.Interval = $IntervalSeconds * 1000
    $timer.AutoReset = $true

    $action = {
        try {
            & $CheckScript
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 检查异常：$($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action $action -SourceIdentifier $Name
    $timer.Start()

    Write-Host "定时检查已启动：$Name（间隔 ${IntervalSeconds}s）" -ForegroundColor Green
    return $timer
}

# 每 60 秒检查磁盘空间
$diskTimer = Start-PeriodicCheck -Name "DiskSpaceCheck" -IntervalSeconds 60 -CheckScript {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedPct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)

    if ($usedPct -gt 90) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 磁盘告警！C盘使用率 $usedPct%，剩余 $freeGB GB" -ForegroundColor Red
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] C盘正常：$usedPct%（剩余 $freeGB GB）" -ForegroundColor Green
    }
}

# 每 30 秒检查关键服务
$svcTimer = Start-PeriodicCheck -Name "ServiceCheck" -IntervalSeconds 30 -CheckScript {
    $services = @("W3SVC", "MSSQLSERVER", "MyApp")
    foreach ($svcName in $services) {
        $svc = Get-Service $svcName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne 'Running') {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $svcName 异常：$($svc.Status)" -ForegroundColor Red
        }
    }
}

# 停止定时器
# $diskTimer.Stop()
# $svcTimer.Stop()
# Get-EventSubscriber | Unregister-Event
```

执行结果示例：

```
定时检查已启动：DiskSpaceCheck（间隔 60s）
定时检查已启动：ServiceCheck（间隔 30s）
[08:31:00] C盘正常：72.4%（剩余 55.2 GB）
[08:31:30] [08:32:00] C盘正常：72.4%（剩余 55.2 GB）
```

## Windows 事件日志触发

```powershell
# 监控 Windows 事件日志
function Watch-EventLog {
    param(
        [string]$LogName = "Application",
        [int]$EventId,
        [string]$Source,
        [string]$Level = "Error"
    )

    $query = "*[System/Level=$(switch ($Level) { 'Critical' { 1 } 'Error' { 2 } 'Warning' { 3 } 'Info' { 4 } })]"

    if ($EventId) {
        $query = "*[System/EventID=$EventId]"
    }

    Register-WmiEvent -Query @"
        SELECT * FROM __InstanceCreationEvent WITHIN 5
        WHERE TargetInstance ISA 'Win32_NTLogEvent'
        AND TargetInstance.LogFile = '$LogName'
"@ -SourceIdentifier "EventLog_$LogName" -Action {
        $evt = $Event.SourceEventArgs.NewEvent.TargetInstance
        $time = $evt.TimeGenerated
        $source = $evt.SourceName
        $msg = $evt.Message

        if ($msg.Length -gt 100) { $msg = $msg.Substring(0, 100) + "..." }

        Write-Host "[$time] 事件：$source" -ForegroundColor Yellow
        Write-Host "  $msg" -ForegroundColor DarkGray
    }

    Write-Host "已订阅事件日志：$LogName" -ForegroundColor Green
}

# 监控应用程序错误
Watch-EventLog -LogName "Application" -Level "Error"

# 查看当前所有事件订阅
Write-Host "`n当前事件订阅：" -ForegroundColor Cyan
Get-EventSubscriber | Select-Object SourceIdentifier, SubscriptionId |
    Format-Table -AutoSize
```

执行结果示例：

```
已订阅事件日志：Application

当前事件订阅：
SourceIdentifier      SubscriptionId
-----------------      --------------
ProcessCreated                    1
ServiceStateChanged               2
FileArrival                       3
DiskSpaceCheck                    4
ServiceCheck                      5
EventLog_Application              6
```

## 注意事项

1. **事件队列**：PowerShell 事件存储在内存队列中，长时间运行可能积压大量事件，定期用 `Get-Event` 处理
2. **资源释放**：事件订阅和 FileSystemWatcher 使用完毕后必须清理，否则会持续消耗资源
3. **WITHIN 间隔**：WMI 事件的 `WITHIN` 参数控制轮询间隔，间隔越短 CPU 使用越高
4. **事件丢失**：高频事件可能被丢弃（缓冲区溢出），关键场景需要补充轮询机制
5. **会话限制**：事件订阅只在当前 PowerShell 会话中有效，需要持久化请使用计划任务或 Windows 服务
6. **权限要求**：某些 WMI 事件订阅需要管理员权限
