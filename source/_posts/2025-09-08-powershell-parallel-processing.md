---
layout: post
date: 2025-09-08 08:00:00
title: "PowerShell 技能连载 - 并行处理实战"
description: PowerTip of the Day - Parallel Processing in Practice with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- parallel
- runspace
- performance
---

_适用于 PowerShell 7.0 及以上版本（部分示例兼容 5.1）_

随着服务器核心数增加和运维任务量增长，单线程处理已经无法满足效率需求。PowerShell 7 引入了 `ForEach-Object -Parallel`，让并行处理变得像管道一样简单。对于仍在使用 PowerShell 5.1 的环境，.NET 的 Runspace API 同样提供了强大的并行能力。合理使用并行处理，可以将原本需要数小时的任务缩短到几分钟。

本文将对比不同的并行方案，并给出实用的并行处理模式。

## ForEach-Object -Parallel

```powershell
# 基本并行用法（PowerShell 7+）
$servers = @("SRV01", "SRV02", "SRV03", "SRV04", "SRV05")

# 串行获取磁盘信息
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$serial = foreach ($server in $servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name,
            @{N='FreeGB'; E={[math]::Round($_.Free / 1GB, 2)}},
            @{N='UsedGB'; E={[math]::Round($_.Used / 1GB, 2)}}
    }
}
$sw.Stop()
Write-Host "串行执行：$($sw.ElapsedMilliseconds) ms"

# 并行获取磁盘信息
$sw.Restart()
$parallel = $servers | ForEach-Object -ThrottleLimit 5 -Parallel {
    Invoke-Command -ComputerName $_ -ScriptBlock {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name,
            @{N='FreeGB'; E={[math]::Round($_.Free / 1GB, 2)}},
            @{N='UsedGB'; E={[math]::Round($_.Used / 1GB, 2)}}
    }
}
$sw.Stop()
Write-Host "并行执行：$($sw.ElapsedMilliseconds) ms"

# 带返回值的并行处理
$results = 1..100 | ForEach-Object -ThrottleLimit 10 -Parallel {
    # 模拟耗时计算
    Start-Sleep -Milliseconds 50
    [PSCustomObject]@{
        Input   = $_
        Squared = $_ * $_
        Thread  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
}

$uniqueThreads = $results.Thread | Sort-Object -Unique
Write-Host "使用了 $($uniqueThreads.Count) 个线程处理 100 个任务"
$results | Select-Object -First 5 | Format-Table -AutoSize
```

执行结果示例：

```
串行执行：12534 ms
并行执行：3102 ms
使用了 6 个线程处理 100 个任务
Input Squared Thread
----- ------- ------
    1       1      7
    2       4      8
    3       9      4
    4      16      7
    5      25      8
```

## 变量传递与状态共享

```powershell
# 向并行代码块传递变量
$threshold = 80
$warningEmail = "admin@contoso.com"

$drives = @(
    @{ Server = "SRV01"; Drive = "C:" },
    @{ Server = "SRV02"; Drive = "D:" },
    @{ Server = "SRV03"; Drive = "C:" }
)

$alerts = $drives | ForEach-Object -ThrottleLimit 3 -Parallel {
    # 使用 $using: 引用外部变量
    $thresh = $using:threshold
    $email  = $using:warningEmail

    # 模拟获取磁盘使用率
    $usage = Get-Random -Minimum 50 -Maximum 100

    if ($usage -gt $thresh) {
        [PSCustomObject]@{
            Server    = $_.Server
            Drive     = $_.Drive
            Usage     = $usage
            Alert     = "$($_.Server) $($_.Drive) 使用率 ${usage}% 超过阈值 ${thresh}%"
            NotifyTo  = $email
        }
    }
}

if ($alerts) {
    Write-Host "磁盘告警：" -ForegroundColor Red
    $alerts | Format-Table Server, Drive, Usage, Alert -AutoSize
} else {
    Write-Host "所有磁盘使用率正常" -ForegroundColor Green
}

# 使用 ConcurrentDictionary 共享状态（线程安全）
$counter = [System.Collections.Concurrent.ConcurrentDictionary[string, int]]::new()

1..50 | ForEach-Object -ThrottleLimit 10 -Parallel {
    $dict = $using:counter
    $category = @("Web", "API", "DB", "Cache")[(Get-Random -Minimum 0 -Maximum 4)]
    $dict.AddOrUpdate($category, 1, { param($k, $v) $v + 1 })
}

Write-Host "`n分类统计：" -ForegroundColor Cyan
$counter.GetEnumerator() | Sort-Object Value -Descending |
    ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }
```

执行结果示例：

```
磁盘告警：
Server Drive Usage Alert
------ ----- ----- -----
SRV01  C:      92  SRV01 C: 使用率 92% 超过阈值 80%
SRV03  C:      87  SRV03 C: 使用率 87% 超过阈值 80%

分类统计：
  Web: 16
  API: 14
  DB: 11
  Cache: 9
```

## Runspace 池（兼容 5.1）

```powershell
# PowerShell 5.1 兼容的并行方案
function Invoke-RunspaceJob {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [object[]]$InputData,

        [int]$ThrottleLimit = 4
    )

    $pool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
    $pool.Open()

    $jobs = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($item in $InputData) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool

        # 添加脚本和参数
        $ps.AddScript($ScriptBlock).AddArgument($item) | Out-Null

        $jobs.Add(@{
            PowerShell = $ps
            Handle     = $ps.BeginInvoke()
            Input      = $item
        })
    }

    # 等待所有任务完成
    $results = @()
    foreach ($job in $jobs) {
        try {
            $output = $job.PowerShell.EndInvoke($job.Handle)
            if ($output) { $results += $output }
        } catch {
            Write-Host "任务失败：$($job.Input) - $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            $job.PowerShell.Dispose()
        }
    }

    $pool.Close()
    $pool.Dispose()

    return $results
}

# 使用 Runspace 并行 Ping 测试
$computers = @(
    "SRV01", "SRV02", "SRV03", "SRV04", "SRV05",
    "DB01", "DB02", "WEB01", "WEB02", "APP01"
)

$pingResults = Invoke-RunspaceJob -InputData $computers -ThrottleLimit 5 -ScriptBlock {
    param([string]$Computer)

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ping = Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction SilentlyContinue
    $sw.Stop()

    [PSCustomObject]@{
        Computer  = $Computer
        Online    = $ping
        LatencyMs = $sw.ElapsedMilliseconds
    }
}

$pingResults | Sort-Object Computer | Format-Table -AutoSize

$online = ($pingResults | Where-Object { $_.Online }).Count
Write-Host "在线：$online / $($computers.Count)" -ForegroundColor Green
```

执行结果示例：

```
Computer Online LatencyMs
-------- ------ ---------
APP01       True         2
DB01        True         3
DB02        True         2
SRV01       True         1
SRV02       True         2
SRV03       True         1
SRV04       True         2
SRV05       True         2
WEB01       True         3
WEB02       True         2
在线：10 / 10
```

## 并行文件处理

```powershell
# 并行处理大量文件
function Invoke-ParallelFileProcess {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [scriptblock]$ProcessBlock,

        [string]$Filter = "*.*",
        [int]$ThrottleLimit = 4
    )

    $files = Get-ChildItem $Path -Filter $Filter -File
    Write-Host "找到 $($files.Count) 个文件，使用 $ThrottleLimit 并发处理" -ForegroundColor Cyan

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $results = $files | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
        $file = $_
        $block = $using:ProcessBlock

        try {
            & $block $file
        } catch {
            [PSCustomObject]@{
                File  = $file.Name
                Error = $_.Exception.Message
                Status = "Failed"
            }
        }
    }

    $sw.Stop()

    $success = ($results | Where-Object { $_.Status -ne "Failed" }).Count
    $failed  = ($results | Where-Object { $_.Status -eq "Failed" }).Count

    Write-Host "`n处理完成：成功 $success，失败 $failed" -ForegroundColor $(if ($failed) { "Yellow" } else { "Green" })
    Write-Host "耗时：$($sw.ElapsedMilliseconds) ms"

    return $results
}

# 示例：批量计算文件哈希
$hashResults = Invoke-ParallelFileProcess -Path "C:\Projects\MyApp\bin" -Filter "*.dll" -ThrottleLimit 8 -ProcessBlock {
    param($file)
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
    [PSCustomObject]@{
        File   = $file.Name
        SizeKB = [math]::Round($file.Length / 1KB, 2)
        SHA256 = $hash.Substring(0, 16) + "..."
        Status = "OK"
    }
}

$hashResults | Format-Table -AutoSize
```

执行结果示例：

```
找到 24 个文件，使用 8 并发处理

处理完成：成功 24，失败 0
耗时：1234 ms
File            SizeKB SHA256            Status
----            ------ ------            ------
Microsoft.AI.dll  456.78 a1b2c3d4e5f6... OK
Newtonsoft.Json  1234.56 f1e2d3c4b5a6... OK
System.Text.Json  234.56 1a2b3c4d5e6f... OK
MyApp.Core.dll    567.89 b2c3d4e5f6a1... OK
```

## 注意事项

1. **并发数控制**：`ThrottleLimit` 不是越大越好，CPU 密集型任务设为 CPU 核心数，I/O 密集型可设为 2-4 倍
2. **线程安全**：并行代码中不要直接修改外部变量，使用 `$using:` 传递只读数据，或使用 `ConcurrentDictionary` 共享可变状态
3. **错误处理**：每个并行任务应有独立的 `try-catch`，避免一个任务失败导致整个并行操作中断
4. **内存消耗**：每个 runspace 有独立的内存空间，大量并发会消耗更多内存
5. **调试困难**：并行代码的调试比串行代码复杂得多，建议先用串行模式验证逻辑正确性
6. **PowerShell 7 优势**：`ForEach-Object -Parallel` 是 PowerShell 7 独有功能，5.1 只能使用 Runspace 方案
