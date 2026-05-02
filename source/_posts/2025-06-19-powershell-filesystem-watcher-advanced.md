---
layout: post
date: 2025-06-19 08:00:00
updated: 2025-06-19 08:00:00
title: "PowerShell 技能连载 - 文件系统监控进阶"
description: PowerTip of the Day - Advanced File System Monitoring in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- filesystem
- watcher
- event-handling
---

_适用于 PowerShell 5.1 及以上版本（Windows），FileSystemWatcher 需要 .NET Framework/Core_

文件系统监控是自动化运维的重要能力——监控配置文件变更触发服务重载、监控上传目录自动处理新文件、监控日志目录异常增长告警。.NET 的 `FileSystemWatcher` 类提供了操作系统级的文件变更通知机制，比轮询扫描高效得多。结合 PowerShell 的事件处理能力，可以构建响应迅速的文件系统自动化工作流。

本文将讲解 FileSystemWatcher 的高级用法、事件处理模式，以及实用的自动化场景。

<!-- more -->

## 基础文件监控

```powershell
# 创建 FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\Config"
$watcher.Filter = "*.json"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# 注册事件处理器
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    Write-Host "[$timestamp] $changeType : $name" -ForegroundColor Yellow

    switch ($changeType) {
        'Changed'  { Write-Host "  文件已修改：$path" -ForegroundColor Cyan }
        'Created'  { Write-Host "  新文件：$path" -ForegroundColor Green }
        'Deleted'  { Write-Host "  文件已删除：$path" -ForegroundColor Red }
        'Renamed'  {
            $oldName = $Event.SourceEventArgs.OldName
            Write-Host "  重命名：$oldName => $name" -ForegroundColor Yellow
        }
    }
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -SourceIdentifier "FileChanged"
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier "FileCreated"
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -SourceIdentifier "FileDeleted"
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -SourceIdentifier "FileRenamed"

Write-Host "文件监控已启动：C:\Config\*.json" -ForegroundColor Green
Write-Host "按 Enter 停止监控..." -ForegroundColor DarkGray
Read-Host

# 清理
Get-EventSubscriber | Unregister-Event
$watcher.EnableRaisingEvents = $false
$watcher.Dispose()
```

执行结果示例：

```
文件监控已启动：C:\Config\*.json
[2025-06-19 08:30:15] Changed : appsettings.json
  文件已修改：C:\Config\appsettings.json
[2025-06-19 08:30:45] Created : new-config.json
  新文件：C:\Config\new-config.json
```

## 配置文件变更自动重载

当应用配置文件变更时，自动触发服务重载：

```powershell
function Start-ConfigAutoReload {
    <#
    .SYNOPSIS
    监控配置文件变更，自动重载服务
    #>
    param(
        [Parameter(Mandatory)]
        [string]$WatchPath,

        [string]$Filter = "*.json",

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [int]$DebounceSeconds = 5
    )

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WatchPath
    $watcher.Filter = $Filter
    $watcher.EnableRaisingEvents = $true

    $lastReload = [datetime]::MinValue

    $action = {
        $now = Get-Date
        if (($now - $lastReload).TotalSeconds -lt $DebounceSeconds) {
            return
        }
        $script:lastReload = $now

        $fileName = $Event.SourceEventArgs.Name
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 检测到配置变更：$fileName" -ForegroundColor Yellow

        # 验证 JSON 有效性
        try {
            $content = Get-Content $Event.SourceEventArgs.FullPath -Raw | ConvertFrom-Json
            Write-Host "  JSON 验证通过" -ForegroundColor Green
        } catch {
            Write-Host "  JSON 验证失败，跳过重载：$($_.Exception.Message)" -ForegroundColor Red
            return
        }

        # 重启服务
        Write-Host "  正在重启服务：$ServiceName..." -ForegroundColor Cyan
        Restart-Service -Name $ServiceName -Force
        $svc = Get-Service $ServiceName
        Write-Host "  服务状态：$($svc.Status)" -ForegroundColor $(if ($svc.Status -eq 'Running') { 'Green' } else { 'Red' })
    }

    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action `
        -SourceIdentifier "ConfigAutoReload_$ServiceName"

    Write-Host "配置自动重载已启动" -ForegroundColor Green
    Write-Host "  监控路径：$WatchPath\$Filter"
    Write-Host "  目标服务：$ServiceName"
}

# 启动监控
Start-ConfigAutoReload -WatchPath "C:\MyApp\config" `
    -ServiceName "MyApp" -DebounceSeconds 5
```

执行结果示例：

```
配置自动重载已启动
  监控路径：C:\MyApp\config\*.json
  目标服务：MyApp
[08:30:15] 检测到配置变更：appsettings.json
  JSON 验证通过
  正在重启服务：MyApp...
  服务状态：Running
```

## 上传目录自动处理

监控上传目录，自动处理新到达的文件：

```powershell
function Start-UploadProcessor {
    <#
    .SYNOPSIS
    监控上传目录，自动处理新文件
    #>
    param(
        [string]$UploadPath = "C:\Uploads",
        [string]$ProcessedPath = "C:\Uploads\processed",
        [string]$ErrorPath = "C:\Uploads\errors"
    )

    foreach ($path in @($UploadPath, $ProcessedPath, $ErrorPath)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $UploadPath
    $watcher.Filter = "*.csv"
    $watcher.EnableRaisingEvents = $true

    $action = {
        $filePath = $Event.SourceEventArgs.FullPath
        $fileName = $Event.SourceEventArgs.Name

        # 等待文件完全写入（避免读取未完成的文件）
        Start-Sleep -Seconds 2

        # 检查文件是否仍在被写入
        try {
            $stream = [System.IO.File]::Open($filePath, 'Open', 'Read', 'Read')
            $stream.Close()
        } catch {
            Write-Host "文件仍被锁定，跳过：$fileName" -ForegroundColor DarkGray
            return
        }

        Write-Host "处理文件：$fileName" -ForegroundColor Cyan

        try {
            # 读取并处理 CSV
            $data = Import-Csv $filePath
            $rowCount = $data.Count

            # 模拟数据处理
            foreach ($row in $data) {
                # 处理逻辑...
            }

            # 移动到已处理目录
            $destPath = Join-Path $ProcessedPath $fileName
            Move-Item $filePath $destPath -Force
            Write-Host "  已处理 $rowCount 行，移至：$destPath" -ForegroundColor Green

        } catch {
            $errorPath = Join-Path $ErrorPath $fileName
            Move-Item $filePath $errorPath -Force
            Write-Host "  处理失败，移至：$errorPath" -ForegroundColor Red
            Write-Host "  错误：$($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action `
        -SourceIdentifier "UploadProcessor"

    Write-Host "上传处理器已启动：$UploadPath" -ForegroundColor Green
}

Start-UploadProcessor
```

执行结果示例：

```
上传处理器已启动：C:\Uploads
处理文件：customers-20250619.csv
  已处理 150 行，移至：C:\Uploads\processed\customers-20250619.csv
```

## 注意事项

1. **文件锁检测**：新创建的文件可能仍在被写入，处理前应等待并检测文件锁
2. **防抖处理**：同一文件的修改可能在短时间内触发多次事件，使用时间戳去重
3. **缓冲区大小**：大量快速变更时，`FileSystemWatcher` 的内部缓冲区可能溢出。通过 `InternalBufferSize` 属性增大缓冲区
4. **网络驱动器**：FileSystemWatcher 对网络路径（UNC 路径）的监控不太可靠，建议在文件服务器本地运行
5. **资源释放**：使用完毕后务必调用 `Dispose()` 释放 FileSystemWatcher 和取消事件订阅
6. **事件队列**：PowerShell 的事件队列可能积压，定期使用 `Get-Event` 处理或设置队列大小限制
