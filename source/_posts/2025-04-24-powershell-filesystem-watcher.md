---
layout: post
date: 2025-04-24 08:00:00
updated: 2025-04-24 08:00:00
title: "PowerShell 技能连载 - 文件系统变更监控"
description: PowerTip of the Day - File System Change Monitoring with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- filesystem
- monitoring
- automation
---

_适用于 PowerShell 7.0 及以上版本（Windows）_

<!-- more -->

## 背景

在日常工作和技术运维中，我们经常需要知道某个目录下发生了什么变化：配置文件是否被篡改、日志目录是否有新文件生成、用户文档是否被意外删除。传统的做法是写一个轮询脚本，每隔几秒扫描一次目录，但这种方式既低效又容易遗漏变化。

.NET 提供的 `System.IO.FileSystemWatcher` 类可以监听文件系统的变更事件，当目标目录中出现文件创建、修改、删除或重命名时，它会立即触发通知。结合 PowerShell 的事件注册机制，我们可以构建出高效、实时的文件系统监控方案——从安全审计到自动构建，再到实时备份，都可以基于这套机制实现。

## FileSystemWatcher 基础

`FileSystemWatcher` 是 .NET 内置的文件系统监控组件。使用时需要指定要监控的目录路径，并配置需要监听的事件类型。下面是最基本的创建和启用方式：

```powershell
# 创建 FileSystemWatcher 实例
$watcher = [System.IO.FileSystemWatcher]::new()

# 设置监控路径
$watcher.Path = "C:\Logs"

# 启用变更事件触发
$watcher.EnableRaisingEvents = $true

# 查看当前配置
$watcher | Format-List Path, Filter, EnableRaisingEvents
```

```
Path                 : C:\Logs
Filter               : *.*
EnableRaisingEvents  : True
```

创建 `FileSystemWatcher` 后，`Path` 属性指定了要监控的目录，`EnableRaisingEvents` 设为 `$true` 后才会真正开始触发事件。默认情况下 `Filter` 为 `*.*`，表示监控所有文件。注意，此时虽然已经启用了事件触发，但我们还没有注册任何事件处理器，所以即使目录发生变化也不会有任何响应。

## 监控文件创建、修改、删除与重命名

`FileSystemWatcher` 提供了四类核心事件：`Created`、`Changed`、`Deleted` 和 `Renamed`。我们可以使用 PowerShell 的 `Register-ObjectEvent` 来订阅这些事件，并通过 `-Action` 参数指定事件触发时执行的脚本块。

```powershell
$watcher = [System.IO.FileSystemWatcher]::new("C:\Logs")
$watcher.EnableRaisingEvents = $true

# 注册创建事件
Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier "FileCreated" -Action {
    $name = $Event.SourceEventArgs.Name
    $fullPath = $Event.SourceEventArgs.FullPath
    $time = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$time] 文件创建: $name ($fullPath)"
}

# 注册修改事件
Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier "FileChanged" -Action {
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    $time = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$time] 文件修改: $name ($changeType)"
}

# 注册删除事件
Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier "FileDeleted" -Action {
    $name = $Event.SourceEventArgs.Name
    $time = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$time] 文件删除: $name"
}

# 注册重命名事件
Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier "FileRenamed" -Action {
    $oldName = $Event.SourceEventArgs.OldName
    $newName = $Event.SourceEventArgs.Name
    $time = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$time] 文件重命名: $oldName -> $newName"
}

Write-Host "已注册全部事件，正在监控 C:\Logs ..."
```

注册完成后，每当 `C:\Logs` 目录下发生对应的文件操作，PowerShell 就会在后台执行相应的 Action 脚本块。此时如果我们在另一个终端中操作文件，监控端就会输出对应的日志信息。

```
[2025-04-24 10:15:32] 文件创建: newfile.txt (C:\Logs\newfile.txt)
[2025-04-24 10:15:45] 文件修改: newfile.txt (Changed)
[2025-04-24 10:16:01] 文件重命名: newfile.txt -> report.txt
[2025-04-24 10:16:20] 文件删除: report.txt
```

需要注意，`Changed` 事件可能被多次触发——例如用记事本保存文件时，文件的内容和属性可能分别触发一次 `Changed` 事件。这在后续处理中需要做去重处理。

## 过滤器与监控范围设置

在实际场景中，我们往往不需要监控目录下的所有文件。`FileSystemWatcher` 提供了 `Filter` 和 `IncludeSubdirectories` 两个属性来精确控制监控范围。

```powershell
$watcher = [System.IO.FileSystemWatcher]::new("C:\Project\src")

# 只监控 .log 文件
$watcher.Filter = "*.log"

# 同时监控子目录
$watcher.IncludeSubdirectories = $true

# 设置缓冲区大小（默认 8KB，频繁变更时需要加大）
$watcher.InternalBufferSize = 65536  # 64KB

$watcher.EnableRaisingEvents = $true

# 注册事件，只关注 Created 和 Changed
Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier "LogCreated" -Action {
    $path = $Event.SourceEventArgs.FullPath
    $time = $Event.TimeGenerated.ToString("HH:mm:ss.fff")
    Write-Host "[$time] 新日志: $path"
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier "LogChanged" -Action {
    $path = $Event.SourceEventArgs.FullPath
    $time = $Event.TimeGenerated.ToString("HH:mm:ss.fff")
    Write-Host "[$time] 日志更新: $path"
}

Write-Host "正在监控 C:\Project\src 及子目录中的 *.log 文件..."
```

```
[10:20:15.123] 新日志: C:\Project\src\app\debug.log
[10:20:15.456] 日志更新: C:\Project\src\app\debug.log
[10:21:30.789] 新日志: C:\Project\src\api\access.log
```

`Filter` 属性只支持简单的通配符模式（如 `*.log`、`*.txt`），不支持正则表达式或多个扩展名的组合过滤。如果需要同时监控 `.log` 和 `.txt`，可以创建多个 `FileSystemWatcher` 实例，或者在 Action 中用条件判断自行过滤。`InternalBufferSize` 的设置很重要——当短时间内文件变更过于频繁时，默认的 8KB 缓冲区可能不够用，导致事件丢失。微软建议将其设置为 4KB 的整数倍，最大可到 64KB。

## 事件注册处理与生命周期管理

PowerShell 的事件订阅不会自动清理，如果不主动注销，它们会一直占用资源。良好的做法是在脚本中记录所有订阅标识，并在不再需要时统一注销。此外，事件处理器中产生的输出不会直接显示在控制台，而是存储在后台作业中，需要用 `Receive-Job` 来查看。

```powershell
# 定义所有订阅标识
$subscriptionIds = @(
    "FSW_Created",
    "FSW_Changed",
    "FSW_Deleted",
    "FSW_Renamed"
)

$watcher = [System.IO.FileSystemWatcher]::new("C:\Config")
$watcher.EnableRaisingEvents = $true

# 注册事件并收集作业信息
$jobs = @()
$events = @("Created", "Changed", "Deleted", "Renamed")
$ids = $subscriptionIds

for ($i = 0; $i -lt $events.Count; $i++) {
    $job = Register-ObjectEvent -InputObject $watcher `
        -EventName $events[$i] `
        -SourceIdentifier $ids[$i] `
        -Action {
            $info = @{
                Time    = $Event.TimeGenerated
                Type    = $Event.SourceEventArgs.ChangeType
                Path    = $Event.SourceEventArgs.FullPath
                Name    = $Event.SourceEventArgs.Name
            }
            # 将事件信息写入流，方便后续检索
            [PSCustomObject]$info
        }
    $jobs += $job
}

Write-Host "已注册 $($events.Count) 个事件订阅"

# 查看当前所有事件订阅
Get-EventSubscriber | Format-Table SourceIdentifier, SubscriptionId, AutoUnregister

# 查看后台作业中收集到的事件
Start-Sleep -Seconds 5  # 等待一些事件发生
foreach ($job in $jobs) {
    $results = Receive-Job -Job $job -ErrorAction SilentlyContinue
    if ($results) {
        $results | Format-Table Time, Type, Name -AutoSize
    }
}
```

```
SourceIdentifier SubscriptionId AutoUnregister
----------------- -------------- --------------
FSW_Created                    1           False
FSW_Changed                    2           False
FSW_Deleted                    3           False
FSW_Renamed                    4           False

Time                  Type    Name
----                  ----    ----
2025/4/24 10:30:15    Created appsettings.json
2025/4/24 10:30:22    Changed appsettings.json
2025/4/24 10:31:05    Renamed  old_config.json
```

使用完毕后，务必清理订阅和作业，否则会造成内存泄漏：

```powershell
# 注销所有事件订阅
foreach ($id in $subscriptionIds) {
    Unregister-Event -SourceIdentifier $id -ErrorAction SilentlyContinue
}

# 移除后台作业
foreach ($job in $jobs) {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
}

# 释放 FileSystemWatcher
$watcher.EnableRaisingEvents = $false
$watcher.Dispose()

Write-Host "已清理所有事件订阅和资源"
```

```
已清理所有事件订阅和资源
```

## 实战：自动备份监控目录

将以上知识点整合起来，我们可以构建一个实用的自动备份脚本。当监控目录中的文件发生变更时，自动将最新版本复制到备份目录中，实现近实时的增量备份。

```powershell
# 自动备份脚本配置
$SourcePath = "C:\ImportantDocs"
$BackupPath = "D:\Backup\ImportantDocs"

# 确保备份目录存在
if (-not (Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
    Write-Host "已创建备份目录: $BackupPath"
}

# 创建 FileSystemWatcher
$watcher = [System.IO.FileSystemWatcher]::new($SourcePath)
$watcher.IncludeSubdirectories = $true
$watcher.InternalBufferSize = 65536
$watcher.EnableRaisingEvents = $true

# 用于去重的哈希表（避免短时间内重复备份同一文件）
$recentBackup = @{}

# 注册创建和修改事件
Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier "Backup_Created" -Action {
    $sourceFile = $Event.SourceEventArgs.FullPath
    $now = Get-Date

    # 去重：5秒内同一文件不重复备份
    if ($recentBackup.ContainsKey($sourceFile) -and
        ($now - $recentBackup[$sourceFile]).TotalSeconds -lt 5) {
        return
    }
    $recentBackup[$sourceFile] = $now

    # 计算备份目标路径
    $relativePath = $sourceFile.Substring($SourcePath.Length).TrimStart("\")
    $targetFile = Join-Path $BackupPath $relativePath

    # 确保目标目录存在
    $targetDir = Split-Path $targetFile -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    # 执行备份
    try {
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        $timeStr = $now.ToString("HH:mm:ss")
        Write-Host "[$timeStr] 备份成功: $relativePath"
    }
    catch {
        Write-Host "[ERROR] 备份失败: $relativePath - $($_.Exception.Message)"
    }
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier "Backup_Changed" -Action {
    $sourceFile = $Event.SourceEventArgs.FullPath
    $now = Get-Date

    # 去重：5秒内同一文件不重复备份
    if ($recentBackup.ContainsKey($sourceFile) -and
        ($now - $recentBackup[$sourceFile]).TotalSeconds -lt 5) {
        return
    }
    $recentBackup[$sourceFile] = $now

    $relativePath = $sourceFile.Substring($SourcePath.Length).TrimStart("\")
    $targetFile = Join-Path $BackupPath $relativePath

    $targetDir = Split-Path $targetFile -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    try {
        # 修改时等待文件写入完成
        Start-Sleep -Milliseconds 500
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        $timeStr = $now.ToString("HH:mm:ss")
        Write-Host "[$timeStr] 增量备份: $relativePath"
    }
    catch {
        Write-Host "[ERROR] 备份失败: $relativePath - $($_.Exception.Message)"
    }
}

Write-Host "自动备份已启动: $SourcePath -> $BackupPath"
Write-Host "按 Ctrl+C 停止监控..."

# 保持脚本运行
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # 清理
    Unregister-Event -SourceIdentifier "Backup_Created" -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier "Backup_Changed" -ErrorAction SilentlyContinue
    Get-Job | Where-Object { $_.Name -match "^Backup_" } | Remove-Job -Force
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Write-Host "监控已停止，资源已释放"
}
```

```
已创建备份目录: D:\Backup\ImportantDocs
自动备份已启动: C:\ImportantDocs -> D:\Backup\ImportantDocs
按 Ctrl+C 停止监控...
[10:45:12] 备份成功: report.docx
[10:45:38] 增量备份: report.docx
[10:46:05] 备份成功: subfolder\notes.txt
监控已停止，资源已释放
```

这个脚本包含了几个实用的设计要点：用哈希表进行去重以避免 `Changed` 事件的重复触发；在备份修改文件时加入了短暂延迟，确保文件写入完成；在 `finally` 块中确保资源始终被正确释放。

## 查看与管理事件订阅

在调试和运维过程中，我们需要随时了解当前有哪些活跃的事件订阅。PowerShell 提供了几个相关命令来管理这些订阅。

```powershell
# 列出当前所有事件订阅
Get-EventSubscriber | Format-Table SourceIdentifier, SubscriptionId, EventName -AutoSize

# 查看后台作业状态
Get-Job | Where-Object { $_.JobStateInfo.State -eq "Running" } |
    Format-Table Id, Name, State -AutoSize

# 查看某个作业的输出
$job = Get-Job | Where-Object { $_.Name -eq "Backup_Created" } | Select-Object -First 1
if ($job) {
    Receive-Job -Job $job -Keep
}

# 紧急清理：注销所有事件订阅
Get-EventSubscriber | Unregister-Event
Get-Job | Remove-Job -Force
Write-Host "已清理全部订阅和作业"
```

```
SourceIdentifier  SubscriptionId EventName
----------------- -------------- ---------
Backup_Created                 1 Created
Backup_Changed                 2 Changed

Id  Name            State
--- ----            -----
 3  Backup_Created  Running
 4  Backup_Changed  Running

已清理全部订阅和作业
```

在调试阶段，善用 `Get-EventSubscriber` 和 `Get-Job` 可以快速定位问题。如果发现某个订阅不再触发事件，首先检查对应的 Job 是否还在运行状态。

## 注意事项

1. **缓冲区溢出导致事件丢失**：当短时间内发生大量文件变更时（如批量编译、解压缩），`FileSystemWatcher` 的内部缓冲区可能溢出。解决方法是增大 `InternalBufferSize`（最大 64KB），并在 Action 中做轻量处理以尽快释放缓冲区。

2. **Changed 事件重复触发**：许多编辑器保存文件时会同时修改文件内容和属性（大小、写入时间等），导致一次保存触发多次 `Changed` 事件。建议在 Action 中加入时间窗口去重逻辑（如上面备份脚本中的 5 秒内去重）。

3. **网络路径的可靠性**：`FileSystemWatcher` 监控网络共享路径时，网络中断会导致监控失效且不会自动恢复。生产环境中应在循环中检测连接状态并重建 Watcher。

4. **文件锁定问题**：文件刚创建或正在写入时，立即读取可能遇到文件锁定。在 Action 中加入短暂延迟（如 `Start-Sleep -Milliseconds 500`）可以缓解这个问题。

5. **资源释放**：`FileSystemWatcher` 实现了 `IDisposable` 接口，使用完毕后必须调用 `Dispose()` 释放资源，同时用 `Unregister-Event` 注销事件订阅、用 `Remove-Job` 清理后台作业，否则会造成内存泄漏。

6. **跨平台限制**：`FileSystemWatcher` 依赖 Windows 的文件系统通知机制，在 Linux/macOS 上的 .NET 虽然也有实现，但行为和可靠性可能有差异。如果需要跨平台方案，可以考虑轮询结合哈希校验的方式。
