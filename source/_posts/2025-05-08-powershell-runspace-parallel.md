---
layout: post
date: 2025-05-08 08:00:00
updated: 2025-05-08 08:00:00
title: "PowerShell 技能连载 - 并行处理与 Runspace"
description: PowerTip of the Day - Parallel Processing and Runspaces in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- runspace
- parallel
- performance
---

_适用于 PowerShell 5.1 及以上版本，ForEach-Object -Parallel 需要 PowerShell 7_

PowerShell 默认是单线程顺序执行的——一个命令完成后再执行下一个。当需要处理数百台服务器、上千个文件或大量 API 请求时，串行执行的等待时间会线性增长。并行处理是解决这类性能瓶颈的关键手段，PowerShell 提供了多种并行方案，从简单到复杂依次为：`Start-Job`、`ForEach-Object -Parallel`、Runspace 池。

本文将对比这三种方案，并深入讲解 Runspace 池的高性能用法。

## 三种并行方案对比

在选择并行方案前，需要了解各方案的特点和适用场景：

| 方案 | 最低版本 | 启动开销 | 内存占用 | 适用场景 |
| ---- | -------- | -------- | -------- | -------- |
| `Start-Job` | 5.1 | 高（新进程） | 高 | 简单后台任务 |
| `ForEach-Object -Parallel` | 7.0 | 中（新 runspace） | 中 | 快速并行遍历 |
| Runspace 池 | 5.1 | 低（线程复用） | 低 | 高性能批量操作 |

```powershell
# 方案一：Start-Job（最简单，但开销最大）
$jobs = @()
$servers = @('SRV01', 'SRV02', 'SRV03', 'SRV04', 'SRV05')

foreach ($server in $servers) {
    $jobs += Start-Job -ScriptBlock {
        param($srv)
        Test-Connection -ComputerName $srv -Count 1 -Quiet
        Get-Service -ComputerName $srv -Name WinRM |
            Select-Object Status, Name
    } -ArgumentList $server
}

# 等待所有作业完成
$results = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

$results | Format-Table -AutoSize
```

执行结果示例：

```
Status Name
------ ----
True   WinRM
True   WinRM
False  WinRM
True   WinRM
True   WinRM
```

## ForEach-Object -Parallel（PowerShell 7+）

PowerShell 7 引入了 `ForEach-Object -Parallel`，这是最便捷的并行方案。它在底层使用新的 runspace 来并行执行脚本块，支持控制并发数和超时：

```powershell
# 基本用法：并行 ping 多台服务器
$servers = 1..50 | ForEach-Object { "192.168.1.$_" }

$servers | ForEach-Object -Parallel {
    $result = Test-Connection -ComputerName $_ -Count 1 -Quiet
    [PSCustomObject]@{
        Server = $_
        Online = $result
        Time   = Get-Date -Format 'HH:mm:ss.fff'
    }
} -ThrottleLimit 10 | Sort-Object Server | Format-Table -AutoSize
```

执行结果示例：

```
Server       Online Time
------       ------ ----
192.168.1.1   True  08:15:32.123
192.168.1.2   True  08:15:32.156
192.168.1.3  False  08:15:32.189
...
```

```powershell
# 传递外部变量到并行脚本块
$credential = Get-Credential
$logPath = "C:\Logs"

1..20 | ForEach-Object -Parallel {
    # 使用 $using: 引用外部变量
    $server = "SRV$_"
    $session = New-PSSession -ComputerName $server -Credential $using:credential

    Invoke-Command -Session $session -ScriptBlock {
        Get-EventLog -LogName System -Newest 10 |
            Select-Object TimeGenerated, EntryType, Message
    } | Export-Csv "$using:logPath\$server-events.csv" -NoTypeInformation

    Remove-PSSession $session
    Write-Host "完成：$server"
} -ThrottleLimit 5 -AsJob | Wait-Job
```

执行结果示例：

```
完成：SRV1
完成：SRV2
完成：SRV3
...
```

> **注意**：`$using:` 语法用于将外部变量传递到并行脚本块中。但 `$using:` 只能传递可序列化的对象，不能传递活动会话或运行时对象。

## Runspace 池高性能并行

Runspace 是 PowerShell 执行环境的最小单元。通过手动创建和管理 runspace，可以实现最低的启动开销和最高的吞吐量。这是处理大规模并行任务的最优方案：

```powershell
# 创建 Runspace 池
$maxThreads = 8
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads)
$runspacePool.Open()

# 定义任务列表
$servers = @('SRV01', 'SRV02', 'SRV03', 'SRV04', 'SRV05',
             'SRV06', 'SRV07', 'SRV08', 'SRV09', 'SRV10')

$scriptBlock = {
    param($ServerName)
    $startTime = Get-Date

    # 模拟远程操作（实际中替换为真实命令）
    Start-Sleep -Milliseconds (Get-Random -Min 100 -Max 500)

    $cpu = Get-Random -Min 10 -Max 95
    $mem = Get-Random -Min 30 -Max 85

    [PSCustomObject]@{
        Server   = $ServerName
        CPU      = $cpu
        Memory   = $mem
        Status   = if ($cpu -gt 80) { 'Warning' } else { 'OK' }
        Duration = ((Get-Date) - $startTime).TotalMilliseconds
    }
}

# 创建并启动所有 Runspace
$runspaces = @()
foreach ($server in $servers) {
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($server)
    $powershell.RunspacePool = $runspacePool

    $runspaces += [PSCustomObject]@{
        Pipe      = $powershell
        Handle    = $powershell.BeginInvoke()
        Server    = $server
    }
}

# 收集结果
$results = @()
foreach ($rs in $runspaces) {
    $result = $rs.Pipe.EndInvoke($rs.Handle)
    if ($result) {
        $results += $result
    }
    $rs.Pipe.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()

$results | Sort-Object Server | Format-Table -AutoSize
```

执行结果示例：

```
Server CPU Memory Status  Duration
------ --- ------ ------  --------
SRV01   45     62  OK       312.45
SRV02   72     58  OK       287.33
SRV03   89     81  Warning  456.12
SRV04   34     45  OK       198.67
SRV05   56     71  OK       234.89
...
```

## 带 进度反馈的 Runspace

长时间运行的并行任务需要进度反馈。通过将 runspace 状态存入字典，可以实时查询进度：

```powershell
$maxThreads = 4
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads)
$runspacePool.Open()

$tasks = 1..20 | ForEach-Object { "Task-$_" }
$scriptBlock = {
    param($TaskName)
    $totalSteps = 5
    for ($step = 1; $step -le $totalSteps; $step++) {
        Start-Sleep -Milliseconds (Get-Random -Min 200 -Max 600)
    }
    [PSCustomObject]@{
        Task   = $TaskName
        Status = 'Completed'
        Steps  = $totalSteps
    }
}

$runspaces = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()

foreach ($task in $tasks) {
    $ps = [powershell]::Create().AddScript($scriptBlock).AddArgument($task)
    $ps.RunspacePool = $runspacePool
    $handle = $ps.BeginInvoke()

    $runspaces[$task] = [PSCustomObject]@{
        Pipe   = $ps
        Handle = $handle
    }
}

# 等待并显示进度
$completed = 0
$total = $tasks.Count
while ($completed -lt $total) {
    Start-Sleep -Milliseconds 500

    foreach ($key in @($runspaces.Keys)) {
        $rs = $runspaces[$key]
        if ($rs.Handle.IsCompleted -and -not $rs.Done) {
            $rs.Done = $true
            $completed++
            $pct = [math]::Round($completed / $total * 100)
            Write-Progress -Activity "并行任务执行" `
                -Status "$completed / $total 已完成 ($pct%)" `
                -PercentComplete $pct
        }
    }
}

# 收集结果
$results = @()
foreach ($key in @($runspaces.Keys)) {
    $rs = $runspaces[$key]
    $result = $rs.Pipe.EndInvoke($rs.Handle)
    if ($result) { $results += $result }
    $rs.Pipe.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()
$results | Format-Table -AutoSize
```

执行结果示例：

```
Task    Status    Steps
----    ------    -----
Task-1  Completed 5
Task-2  Completed 5
Task-3  Completed 5
...
Task-20 Completed 5
```

## 并行文件处理实战

以下是一个使用 Runspace 池并行处理文件的实用示例——批量计算文件哈希：

```powershell
function Get-FileHashParallel {
    <#
    .SYNOPSIS
    并行计算文件哈希值
    #>
    param(
        [string]$Path = "C:\Projects",
        [int]$ThrottleLimit = 8,
        [string]$Algorithm = 'SHA256'
    )

    $files = Get-ChildItem -Path $Path -File -Recurse |
        Where-Object { $_.Length -gt 1MB }
    Write-Host "共 $($files.Count) 个文件需要计算哈希" -ForegroundColor Cyan

    $pool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
    $pool.Open()

    $script = {
        param($FilePath, $Algo)
        $hash = Get-FileHash -Path $FilePath -Algorithm $Algo
        [PSCustomObject]@{
            File    = $FilePath
            Hash    = $hash.Hash
            SizeMB  = [math]::Round((Get-Item $FilePath).Length / 1MB, 2)
        }
    }

    $runspaces = @()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($file in $files) {
        $ps = [powershell]::Create().AddScript($script)
        $ps.AddArgument($file.FullName).AddArgument($Algorithm) | Out-Null
        $ps.RunspacePool = $pool
        $runspaces += @{ Pipe = $ps; Handle = $ps.BeginInvoke() }
    }

    $results = @()
    foreach ($rs in $runspaces) {
        $result = $rs.Pipe.EndInvoke($rs.Handle)
        if ($result) { $results += $result }
        $rs.Pipe.Dispose()
    }

    $pool.Close()
    $pool.Dispose()
    $sw.Stop()

    Write-Host "`n耗时：$($sw.Elapsed.TotalSeconds) 秒" -ForegroundColor Green
    $results | Format-Table -AutoSize
}

Get-FileHashParallel -Path "C:\Projects" -ThrottleLimit 8
```

执行结果示例：

```
共 42 个文件需要计算哈希

耗时：3.82 秒

File                              Hash                                SizeMB
----                              ----                                ------
C:\Projects\app-v1.0.zip          A1B2C3D4E5F6...                   125.3
C:\Projects\database-backup.bak   F6E5D4C3B2A1...                   342.7
C:\Projects\config.json           1234567890AB...                     1.2
```

## 注意事项

1. **线程安全**：Runspace 中的代码不应直接修改外部变量或共享状态，应通过返回值传递结果
2. **并发数控制**：`ThrottleLimit` 或 Runspace 池大小不宜过大，通常设为 CPU 核心数的 2-4 倍
3. **错误处理**：Runspace 中的异常不会自动传播到主线程，需要在脚本块内捕获并通过返回值传递错误信息
4. **资源释放**：使用完毕后必须调用 `Dispose()` 释放 Runspace 和 PowerShell 对象，避免内存泄漏
5. **`$using:` 限制**：`ForEach-Object -Parallel` 中的 `$using:` 只能传递可序列化的值，不能传递 `StreamWriter`、数据库连接等运行时对象
6. **模块导入**：每个 Runspace 是独立的执行环境，需要单独导入模块。可以在脚本块开头添加 `Import-Module` 语句
