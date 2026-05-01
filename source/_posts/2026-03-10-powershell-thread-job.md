---
layout: post
date: 2026-03-10 08:00:00
title: "PowerShell 技能连载 - 后台任务与并发执行"
description: PowerTip of the Day - Background Jobs and Concurrent Execution in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- jobs
- concurrency
- threading
- performance
---

_适用于 PowerShell 7.0 及以上版本_

在日常运维工作中，我们经常遇到需要同时处理大量独立任务的场景。比如批量检查 100 台服务器的连通性、并行下载数十个日志文件、同时对多个数据库执行查询。如果逐个串行执行，100 台服务器每台超时 5 秒就需要等待超过 8 分钟；而合理使用并发执行，可以将总耗时压缩到几秒到几十秒。

PowerShell 历经多年发展，提供了多种并发执行机制。最早期的 `Start-Job` 基于独立的 PowerShell 进程，开销大但隔离性好；后来的 `ThreadJob` 模块改用 .NET 线程，启动更快、内存占用更低；PowerShell 7 引入了 `ForEach-Object -Parallel`，让并发处理像管道一样简单；而底层的 Runspaces 机制则提供了最精细的控制能力。

本文将从易到难，依次介绍这四种并发机制的核心用法、适用场景和注意事项，帮助你根据实际需求选择最合适的方案。

## Start-Job 与 ThreadJob：经典后台任务

`Start-Job` 是 PowerShell 内置的后台任务机制，每个任务在独立的 PowerShell 进程中运行，天然具备良好的隔离性。`ThreadJob` 是社区贡献的模块（PowerShell 7 中已内置），改用 .NET 线程而非进程，启动速度更快、资源开销更小。

下面的示例演示如何创建后台任务、跟踪执行进度并收集结果：

```powershell
# 定义需要检查的服务器列表
$servers = @(
    'server-01.example.com'
    'server-02.example.com'
    'server-03.example.com'
    'server-04.example.com'
    'server-05.example.com'
)

# 方式一：使用 Start-Job（独立进程，开销较大）
$processJobs = foreach ($server in $servers) {
    Start-Job -ScriptBlock {
        param($target)
        $result = Test-Connection -TargetName $target -Count 2 -Quiet
        [PSCustomObject]@{
            Server   = $target
            Online   = $result
            Response = if ($result) { 'OK' } else { 'Timeout' }
        }
    } -ArgumentList $server -Name "Ping_$($server)"
}

# 方式二：使用 ThreadJob（线程级，开销更小）
$threadJobs = foreach ($server in $servers) {
    Start-ThreadJob -ScriptBlock {
        param($target)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Test-Connection -TargetName $target -Count 2 -Quiet
        $sw.Stop()
        [PSCustomObject]@{
            Server    = $target
            Online    = $result
            Duration  = $sw.ElapsedMilliseconds
        }
    } -ArgumentList $server -Name "TPing_$($server)"
}

# 跟踪任务状态
Write-Host "=== 任务状态 ==="
Get-Job | Format-Table Name, State, HasMoreData -AutoSize

# 等待所有 ThreadJob 完成（超时 30 秒）
Wait-Job -Job $threadJobs -Timeout 30 | Out-Null

# 收集结果
Write-Host "`n=== ThreadJob 结果 ==="
$results = $threadJobs | Receive-Job
$results | Format-Table Server, Online, Duration -AutoSize

# 清理已完成任务
Get-Job | Remove-Job
```

执行结果示例：

```
=== 任务状态 ===

Name                                State  HasMoreData
----                                -----  -----------
Ping_server-01.example.com         Running         True
Ping_server-02.example.com         Running         True
Ping_server-03.example.com         Running         True
Ping_server-04.example.com         Running         True
Ping_server-05.example.com         Running         True
TPing_server-01.example.com        Completed       True
TPing_server-02.example.com        Completed       True
TPing_server-03.example.com        Completed       True
TPing_server-04.example.com        Completed       True
TPing_server-05.example.com        Completed       True

=== ThreadJob 结果 ===

Server                     Online Duration
------                     -----  --------
server-01.example.com        True       23
server-02.example.com        True       25
server-03.example.com       False     5012
server-04.example.com        True       18
server-05.example.com        True       31
```

从结果可以看到，ThreadJob 的任务已经快速完成，而 Start-Job 的任务仍在运行中。这是因为 `Start-Job` 每个任务都会启动一个全新的 `pwsh` 进程，初始化开销远大于线程。

## ForEach-Object -Parallel：管道式并发

PowerShell 7 引入了 `ForEach-Object -Parallel` 参数，这是最简洁的并发处理方式。它基于 ThreadJob 实现，在管道中即可实现并行处理，非常适合对集合元素进行并发操作。

`-ThrottleLimit` 参数控制最大并发数，避免资源耗尽；`$using:` 语法允许在并行代码块中引用外部变量。

```powershell
# 模拟一批需要处理的 URL
$urls = @(
    'https://httpbin.org/delay/1'
    'https://httpbin.org/delay/2'
    'https://httpbin.org/delay/1'
    'https://httpbin.org/delay/3'
    'https://httpbin.org/delay/1'
    'https://httpbin.org/delay/2'
    'https://httpbin.org/delay/1'
    'https://httpbin.org/delay/2'
)

# 外部变量：请求超时和重试次数
$timeoutSec = 10
$maxRetries = 2

# 并行请求，限制并发数为 4
$measure = Measure-Command {
    $results = $urls | ForEach-Object -ThrottleLimit 4 -Parallel {
        $url = $_
        $timeout = $using:timeoutSec
        $retries = $using:maxRetries

        $attempt = 0
        $success = $false
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        while ($attempt -lt $retries -and -not $success) {
            $attempt++
            try {
                $response = Invoke-WebRequest -Uri $url -TimeoutSec $timeout `
                    -UseBasicParsing -ErrorAction Stop
                $success = $true
                $sw.Stop()
            }
            catch {
                $sw.Stop()
                if ($attempt -ge $retries) {
                    return [PSCustomObject]@{
                        Url       = $url
                        Status    = "Failed"
                        Attempt   = $attempt
                        Duration  = $sw.ElapsedMilliseconds
                        Error     = $_.Exception.Message
                    }
                }
                $sw.Start()
            }
        }

        [PSCustomObject]@{
            Url      = $url
            Status   = "$($response.StatusCode)"
            Attempt  = $attempt
            Duration = $sw.ElapsedMilliseconds
        }
    }

    $results | Format-Table Url, Status, Attempt, Duration -AutoSize
}

Write-Host "`n总耗时: $($measure.TotalSeconds.ToString('F1')) 秒"
```

执行结果示例：

```
Url                                  Status Attempt Duration
---                                  ------ ------- --------
https://httpbin.org/delay/1             200       1     1023
https://httpbin.org/delay/2             200       1     2015
https://httpbin.org/delay/1             200       1     1018
https://httpbin.org/delay/3             200       1     3012
https://httpbin.org/delay/1             200       1     1025
https://httpbin.org/delay/2             200       1     2020
https://httpbin.org/delay/1             200       1     1019
https://httpbin.org/delay/2             200       1     2015

总耗时: 6.1 秒
```

8 个请求如果串行执行需要约 13 秒（1+2+1+3+1+2+1+2），并行执行（并发数 4）只用了 6.1 秒，效率提升超过 50%。注意 `$using:` 语法是在并行代码块中访问外部变量的唯一方式，直接引用外部变量会导致作用域错误。

## Runspaces：高级并发控制

Runspaces 是 PowerShell 底层的执行环境抽象，每个 PowerShell 实例都运行在一个 Runspace 中。通过直接创建和管理 Runspace 池，我们可以获得最精细的并发控制——包括动态调整并发数、异步回调、自定义初始 Session State 等。

下面演示如何创建 Runspace 池、分发任务并异步收集结果：

```powershell
# 任务列表：批量获取多个远程主机的系统信息
$targets = 1..20 | ForEach-Object { "host-$($_.ToString('00'))" }

# 创建初始 Session State（可预加载模块和变量）
$initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

# 创建 Runspace 池，最大 8 个并发
$runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
    1, 8, $initialSessionState, $Host
)
$runspacePool.Open()

# 定义任务脚本
$scriptBlock = {
    param($computerName)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # 模拟远程查询（实际可用 Invoke-Command 或 CIM 查询）
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 2000)

    $sw.Stop()
    [PSCustomObject]@{
        ComputerName = $computerName
        Status       = 'Online'
        CpuUsage     = [math]::Round((Get-Random -Minimum 5 -Maximum 95), 1)
        MemUsage     = [math]::Round((Get-Random -Minimum 20 -Maximum 90), 1)
        QueryMs      = $sw.ElapsedMilliseconds
    }
}

# 创建并启动所有任务
$runspaces = foreach ($target in $targets) {
    $powershell = [System.Management.Automation.PowerShell]::Create().AddScript($scriptBlock).AddArgument($target)
    $powershell.RunspacePool = $runspacePool

    [PSCustomObject]@{
        PowerShell = $powershell
        Handle     = $powershell.BeginInvoke()
        Target     = $target
    }
}

# 异步等待并收集结果
$completed = [System.Collections.Generic.List[PSObject]]::new()
$totalMs = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($rs in $runspaces) {
    try {
        $result = $rs.PowerShell.EndInvoke($rs.Handle)
        if ($result) {
            $completed.Add($result[0])
        }
    }
    catch {
        $completed.Add([PSCustomObject]@{
            ComputerName = $rs.Target
            Status       = "Error: $($_.Exception.Message)"
            CpuUsage     = 0
            MemUsage     = 0
            QueryMs      = 0
        })
    }
    finally {
        $rs.PowerShell.Dispose()
    }
}

$totalMs.Stop()

# 输出结果（按查询耗时排序）
$completed | Sort-Object QueryMs | Format-Table ComputerName, Status, CpuUsage, MemUsage, QueryMs -AutoSize
Write-Host "`n完成 $($completed.Count)/$($targets.Count) 台，总耗时: $($totalMs.ElapsedMilliseconds) ms"

# 释放 Runspace 池资源
$runspacePool.Close()
$runspacePool.Dispose()
```

执行结果示例：

```
ComputerName Status  CpuUsage MemUsage QueryMs
------------ ------  -------- -------- -------
host-01      Online      12.3     45.2     134
host-05      Online      67.8     52.1     287
host-08      Online      34.5     61.3     412
host-03      Online      89.2     38.7     523
host-12      Online      45.6     72.4     678
host-17      Online      23.1     55.9     789
host-02      Online      56.7     41.8     901
host-19      Online      78.3     63.2    1024
host-06      Online      41.2     47.5    1156
host-10      Online      62.4     58.3    1289
host-15      Online      15.7     69.1    1345
host-04      Online      53.8     43.6    1501
host-09      Online      71.2     51.7    1623
host-14      Online      38.9     65.4    1789
host-20      Online      82.1     37.2    1834
host-07      Online      29.4     54.8    1901
host-11      Online      47.3     62.9    1945
host-13      Online      58.6     49.3    1967
host-16      Online      36.1     71.8    1988
host-18      Online      64.9     44.1    1999

完成 20/20 台，总耗时: 5203 ms
```

20 台主机串行执行需要约 20 秒（平均每台 1 秒），使用 Runspace 池（8 并发）仅用 5.2 秒完成。Runspaces 方案的优势在于可以对执行环境进行深度定制——比如预加载特定模块、设置执行策略、注入共享变量等。

## 注意事项

1. **选择合适的并发机制**：简单场景优先使用 `ForEach-Object -Parallel`（代码最简洁）；需要精细控制并发数和生命周期时使用 `Start-ThreadJob`；需要最大性能和自定义环境时才使用 Runspaces；`Start-Job` 仅在需要完全进程隔离时使用。

2. **合理设置并发数**：并发数并非越高越好。网络 IO 密集型任务可以设置较高并发（如 16-32），CPU 密集型任务建议设置为逻辑核心数。过高的并发会导致上下文切换开销激增，反而降低性能。

3. **注意变量作用域**：`ForEach-Object -Parallel` 中无法直接访问外部变量，必须使用 `$using:` 前缀。`Start-Job` 和 `Start-ThreadJob` 通过 `-ArgumentList` 传参。Runspaces 需要通过 `InitialSessionState` 或参数注入共享数据。

4. **错误处理不能省**：并发任务中的异常不会自动传播到主线程。必须使用 `try/catch` 包裹每个任务逻辑，并在 `Receive-Job` 或 `EndInvoke` 时检查错误。忽略错误处理会导致静默失败，排查困难。

5. **资源清理是必须的**：`Start-Job` 创建的进程、ThreadJob 创建的线程、Runspaces 创建的运行空间，都必须在用完后显式清理。使用 `Remove-Job` 清理 Job，使用 `Dispose()` 释放 Runspace 和 PowerShell 对象，避免内存泄漏。

6. **避免共享可变状态**：并发任务中修改同一个集合或变量会导致竞态条件。应让每个任务返回独立的结果对象，最后在主线程中统一汇总。如果必须共享状态，请使用 .NET 的线程安全集合（如 `ConcurrentDictionary`）。
