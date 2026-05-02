---
layout: post
date: 2025-09-09 08:00:00
updated: 2025-09-09 08:00:00
title: "PowerShell 技能连载 - 文件系统监控"
description: PowerTip of the Day - File System Monitoring in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- filesystem
- filesystemwatcher
- monitoring
---

_适用于 PowerShell 5.1 及以上版本_

在文件服务器和开发环境中，监控文件变化是常见的需求：自动编译源代码变更、检测配置文件被篡改、审计共享文件夹的访问记录。.NET 的 `FileSystemWatcher` 类提供了操作系统级别的文件变更通知，不需要轮询扫描。结合 PowerShell 的事件处理机制，可以构建实时的文件监控和自动响应系统。

本文将介绍 FileSystemWatcher 的配置、事件处理和实际应用场景。

## 基本文件监控

```powershell
# 创建文件系统监控器
$watcher = [System.IO.FileSystemWatcher]::new()
$watcher.Path = "C:\Projects\MyApp"
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor
    [System.IO.NotifyFilters]::LastWrite -bor
    [System.IO.NotifyFilters]::Size

# 注册事件处理
$action = {
    $changeType = $Event.SourceEventArgs.ChangeType
    $fullPath   = $Event.SourceEventArgs.FullPath
    $name       = $Event.SourceEventArgs.Name
    $timestamp  = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss.fff")

    $logEntry = "$timestamp | $changeType | $fullPath"
    $logEntry | Out-File "C:\Logs\FileChanges.log" -Append

    # 根据变更类型输出不同颜色
    switch ($changeType) {
        "Created"  { Write-Host $logEntry -ForegroundColor Green }
        "Changed"  { Write-Host $logEntry -ForegroundColor Yellow }
        "Deleted"  { Write-Host $logEntry -ForegroundColor Red }
        "Renamed"  { Write-Host "$logEntry (from $($Event.SourceEventArgs.OldName))" -ForegroundColor Cyan }
    }
}

# 注册各类事件
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -SourceIdentifier "File.Created" | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action -SourceIdentifier "File.Changed" | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action -SourceIdentifier "File.Deleted" | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action -SourceIdentifier "File.Renamed" | Out-Null

# 启用引发事件
$watcher.EnableRaisingEvents = $true
Write-Host "文件监控已启动：$($watcher.Path)" -ForegroundColor Green
Write-Host "监控子目录：$($watcher.IncludeSubdirectories)" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止监控"

# 查看已注册的事件
Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "File.*" } |
    Select-Object SourceIdentifier, Action |
    Format-Table -AutoSize

# 停止监控（在需要时运行）
# $watcher.EnableRaisingEvents = $false
# Get-EventSubscriber -SourceIdentifier "File.*" | Unregister-Event
# $watcher.Dispose()
```

执行结果示例：

```
文件监控已启动：C:\Projects\MyApp
监控子目录：True
按 Ctrl+C 停止监控
SourceIdentifier  Action
----------------  ------
File.Created      System.Management.Automation.PSEventJob
File.Changed      System.Management.Automation.PSEventJob
File.Deleted      System.Management.Automation.PSEventJob
File.Renamed      System.Management.Automation.PSEventJob
```

## 配置文件变更监控

```powershell
# 监控特定配置文件变化并自动验证
function Start-ConfigFileMonitor {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [string]$LogPath = "C:\Logs\ConfigChanges.log"
    )

    $configDir = Split-Path $ConfigPath -Parent
    $configFile = Split-Path $ConfigPath -Leaf

    $watcher = [System.IO.FileSystemWatcher]::new($configDir, $configFile)
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor
        [System.IO.NotifyFilters]::Size

    $action = {
        $filePath = $Event.SourceEventArgs.FullPath
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # 读取变更后的文件内容
        Start-Sleep -Milliseconds 100  # 等待文件写入完成

        try {
            $content = Get-Content $filePath -Raw -ErrorAction Stop
            $json = $content | ConvertFrom-Json -ErrorAction Stop

            # 验证配置结构
            $required = @("appName", "version", "database")
            $missing = $required | Where-Object {
                -not ($json.PSObject.Properties.Name -contains $_)
            }

            if ($missing) {
                $msg = "$timestamp | INVALID | $filePath | 缺少字段：$($missing -join ', ')"
                Write-Host $msg -ForegroundColor Red
            } else {
                $msg = "$timestamp | VALID | $filePath | version=$($json.version)"
                Write-Host $msg -ForegroundColor Green
            }

            $msg | Out-File $using:LogPath -Append

        } catch {
            $msg = "$timestamp | PARSE_ERROR | $filePath | $($_.Exception.Message)"
            Write-Host $msg -ForegroundColor Red
            $msg | Out-File $using:LogPath -Append
        }
    }

    Register-ObjectEvent -InputObject $watcher -EventName "Changed" `
        -Action $action -SourceIdentifier "Config.Watch" | Out-Null

    $watcher.EnableRaisingEvents = $true
    Write-Host "配置文件监控已启动：$ConfigPath" -ForegroundColor Green

    return $watcher
}

# 启动监控
# $configWatcher = Start-ConfigFileMonitor -ConfigPath "C:\MyApp\appsettings.json"
```

执行结果示例：

```
配置文件监控已启动：C:\MyApp\appsettings.json
2025-09-09 14:30:15 | VALID | C:\MyApp\appsettings.json | version=2.5.0
2025-09-09 14:35:22 | INVALID | C:\MyApp\appsettings.json | 缺少字段：database
```

## 实用监控工具集

```powershell
# 综合文件监控仪表板
function Start-FileMonitorDashboard {
    param(
        [string[]]$Paths = @("C:\Projects", "C:\Config"),
        [int]$DurationMinutes = 30
    )

    $logFile = "C:\Logs\FileMonitor_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $stats = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()
    $stats["Created"] = 0
    $stats["Changed"] = 0
    $stats["Deleted"] = 0
    $stats["Renamed"] = 0

    $watchers = @()
    $endTime = (Get-Date).AddMinutes($DurationMinutes)

    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) {
            Write-Host "路径不存在：$path" -ForegroundColor Red
            continue
        }

        $watcher = [System.IO.FileSystemWatcher]::new()
        $watcher.Path = $path
        $watcher.IncludeSubdirectories = $true
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor
            [System.IO.NotifyFilters]::LastWrite

        $eventAction = {
            $changeType = $Event.SourceEventArgs.ChangeType.ToString()
            $fullPath   = $Event.SourceEventArgs.FullPath
            $timestamp  = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")

            # 更新统计
            $stats = $using:stats
            $stats.AddOrUpdate($changeType, 1, { param($k, $v) $v + 1 })

            # 过滤临时文件
            if ($fullPath -notmatch '\.(tmp|bak|~)$') {
                "$timestamp|$changeType|$fullPath" | Out-File $using:logFile -Append
            }
        }

        "Created", "Changed", "Deleted", "Renamed" | ForEach-Object {
            Register-ObjectEvent -InputObject $watcher -EventName $_ `
                -Action $eventAction -SourceIdentifier "Monitor.$($_).$($path.GetHashCode())" | Out-Null
        }

        $watcher.EnableRaisingEvents = $true
        $watchers += $watcher
        Write-Host "已启动监控：$path" -ForegroundColor Green
    }

    Write-Host "`n监控运行中，时长 $DurationMinutes 分钟..." -ForegroundColor Cyan
    Write-Host "日志文件：$logFile`n"

    # 定期显示统计
    while ((Get-Date) -lt $endTime) {
        Start-Sleep -Seconds 30
        Write-Host "--- $(Get-Date -Format 'HH:mm:ss') 统计 ---" -ForegroundColor Cyan
        foreach ($key in @("Created", "Changed", "Deleted", "Renamed")) {
            Write-Host "  $key : $($stats[$key])"
        }
    }

    # 清理
    foreach ($w in $watchers) {
        $w.EnableRaisingEvents = $false
        $w.Dispose()
    }
    Get-EventSubscriber -SourceIdentifier "Monitor.*" | Unregister-Event

    Write-Host "`n监控已停止。最终统计：" -ForegroundColor Yellow
    foreach ($key in @("Created", "Changed", "Deleted", "Renamed")) {
        Write-Host "  $key : $($stats[$key])"
    }
}

# 启动 5 分钟监控演示
# Start-FileMonitorDashboard -Paths @("C:\Projects") -DurationMinutes 5
```

执行结果示例：

```
已启动监控：C:\Projects
已启动监控：C:\Config

监控运行中，时长 30 分钟...
日志文件：C:\Logs\FileMonitor_20250909_143000.log

--- 14:30:30 统计 ---
  Created : 5
  Changed : 12
  Deleted : 2
  Renamed : 1

监控已停止。最终统计：
  Created : 23
  Changed : 67
  Deleted : 8
  Renamed : 3
```

## 注意事项

1. **缓冲区溢出**：高频文件变更可能超出 FileSystemWatcher 内部缓冲区（默认 8KB），增大 `InternalBufferSize` 属性可缓解
2. **重复事件**：许多编辑器保存文件时会触发多个 Changed 事件，需要用去重逻辑（如时间窗口内相同路径合并）
3. **网络驱动器**：FileSystemWatcher 对网络路径（UNC）的监控不稳定，建议在文件所在服务器本地运行
4. **资源释放**：监控结束或脚本退出前务必调用 `Dispose()` 释放系统资源
5. **权限要求**：监控进程需要对目标目录有读取权限，某些系统目录可能需要管理员权限
6. **事件队列**：如果事件处理脚本执行过慢，事件会堆积在队列中，避免在事件处理中做耗时操作
