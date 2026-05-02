---
layout: post
date: 2025-04-09 08:00:00
updated: 2025-04-09 08:00:00
title: "PowerShell 技能连载 - 并行处理实战"
description: PowerTip of the Day - Parallel Processing
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- scripting
- performance
---

_适用于 PowerShell 7.0 及以上版本_

当我们需要对大量对象执行相同操作时，传统的顺序处理方式往往耗时过长。例如检查 100 台服务器的连通性，逐台 ping 可能需要几分钟，但如果同时发起多个 ping 操作，时间可以缩短到几秒钟。

PowerShell 7 引入了 `ForEach-Object -Parallel` 参数，让并行处理变得前所未有的简单。对于更高级的场景，还可以通过 Runspace 直接操控底层并发机制。本文将系统介绍 PowerShell 中的并行处理方法，帮助你在合适的场景下大幅提升脚本执行效率。

<!-- more -->

## ForEach-Object -Parallel 基础

`ForEach-Object -Parallel` 是 PowerShell 7 新增的功能，它为管道中的每个元素创建一个独立的运行空间来并行执行脚本块。

```powershell
# 顺序 vs 并行：测试多台服务器的连通性
$servers = @(
    "server-01.vichamp.com",
    "server-02.vichamp.com",
    "server-03.vichamp.com",
    "server-04.vichamp.com",
    "server-05.vichamp.com"
)

# 并行测试（同时发起所有 ping）
Measure-Command {
    $servers | ForEach-Object -Parallel {
        $result = Test-Connection -ComputerName $_ -Count 2 -Quiet
        [PSCustomObject]@{
            Server  = $_
            Online  = $result
        }
    } | Format-Table -AutoSize
} | Select-Object TotalSeconds
```

```
Server                   Online
------                   ------
server-01.vichamp.com      True
server-02.vichamp.com      True
server-03.vichamp.com     False
server-04.vichamp.com      True
server-05.vichamp.com      True

TotalSeconds
------------
   2.34
```

## 使用 $using: 传递变量

在 `-Parallel` 脚本块中，不能直接访问外部作用域的变量。需要使用 `$using:` 前缀来引用外部变量。

```powershell
# 从外部传入配置信息
$config = @{
    Port      = 443
    Timeout   = 5000
    AlertTo   = "admin@vichamp.com"
}

$servers | ForEach-Object -Parallel {
    $serverConfig = $using:config
    # 测试 HTTPS 端口连通性
    $tcpClient = [System.Net.Sockets.TcpClient]::new()
    try {
        $asyncResult = $tcpClient.BeginConnect($_, $serverConfig.Port, $null, $null)
        $waited = $asyncResult.AsyncWaitHandle.WaitOne($serverConfig.Timeout, $false)
        [PSCustomObject]@{
            Server = $_
            Port   = $serverConfig.Port
            Open   = $tcpClient.Connected
        }
    } catch {
        [PSCustomObject]@{
            Server = $_
            Port   = $serverConfig.Port
            Open   = $false
        }
    } finally {
        $tcpClient.Close()
    }
} | Format-Table -AutoSize
```

```
Server                    Port  Open
------                    ----  ----
server-01.vichamp.com      443  True
server-02.vichamp.com      443  True
server-03.vichamp.com      443 False
server-04.vichamp.com      443  True
server-05.vichamp.com      443  True
```

### 传递外部函数

如果需要在并行脚本块中调用自定义函数，也需要通过 `$using:` 传递，或者在脚本块内重新定义。

```powershell
# 方式一：使用 $using: 传递函数定义
function Get-ServerHealth {
    param([string]$ServerName)
    # 模拟健康检查
    $cpu = Get-Random -Minimum 10 -Maximum 95
    $mem = Get-Random -Minimum 30 -Maximum 90
    [PSCustomObject]@{
        Server = $ServerName
        CPU    = "$cpu%"
        Memory = "$mem%"
        Status = if ($cpu -gt 85 -or $mem -gt 85) { "警告" } else { "正常" }
    }
}

$healthFunc = ${function:Get-ServerHealth}

$servers | ForEach-Object -Parallel {
    ${function:Get-ServerHealth} = $using:healthFunc
    Get-ServerHealth -ServerName $_
} | Format-Table -AutoSize
```

## 并发限流

当目标数量很大时，不加限制的并行可能会耗尽系统资源。使用 `-ThrottleLimit` 参数可以控制最大并发数。

```powershell
# 限制最大并发数为 5，避免过载
$targets = 1..50 | ForEach-Object { "host-$($_.ToString('00'))" }

$results = $targets | ForEach-Object -ThrottleLimit 5 -Parallel {
    # 模拟网络请求延迟
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
    [PSCustomObject]@{
        Host    = $_
        Latency = "$(Get-Random -Minimum 10 -Maximum 200)ms"
        Checked = (Get-Date).ToString('HH:mm:ss.fff')
    }
}

$results | Format-Table -AutoSize
```

```
Host     Latency Checked
----     ------- --------
host-01  87ms    09:15:23.112
host-02  142ms   09:15:23.234
host-03  35ms    09:15:23.178
...
```

### 动态调整并发数

对于不同类型的任务，最佳并发数不同。可以编写一个带参数的函数来灵活控制。

```powershell
# 可配置的并行批量处理函数
function Invoke-BatchParallel {
    param(
        [Parameter(Mandatory)]
        [array]$Items,
        [scriptblock]$ScriptBlock,
        [int]$ThrottleLimit = 10,
        [int]$TimeoutSeconds = 300
    )

    $results = $Items | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit -AsJob
    $completed = $results | Wait-Job -Timeout $TimeoutSeconds

    $output = $completed | Receive-Job
    $results | Remove-Job -Force

    return $output
}

# 使用示例：批量获取远程服务器的磁盘信息（限流 3 个并发）
$serverList = @("SRV-01", "SRV-02", "SRV-03", "SRV-04", "SRV-05")

Invoke-BatchParallel -Items $serverList -ThrottleLimit 3 -ScriptBlock {
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $_ |
        Select-Object PSComputerName, DeviceID,
            @{N='总空间(GB)';E={[math]::Round($_.Size/1GB,2)}},
            @{N='剩余(GB)';E={[math]::Round($_.FreeSpace/1GB,2)}},
            @{N='使用率';E={"$([math]::Round(($_.Size - $_.FreeSpace)/$_.Size * 100, 1))%"}}
} | Format-Table -AutoSize
```

## 使用 Runspace 实现高级并行

对于需要更精细控制的场景，可以直接使用 .NET 的 Runspace 来创建线程池。这种方式比 `ForEach-Object -Parallel` 更底层，但灵活性更高。

```powershell
# 使用 Runspace 池进行并行处理
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 8)
$runspacePool.Open()

$jobs = foreach ($server in $servers) {
    $powershell = [powershell]::Create().AddScript({
        param($ComputerName)
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
        [PSCustomObject]@{
            Server      = $ComputerName
            OS          = $os.Caption
            LastBoot    = $os.LastBootUpTime
            UptimeDays  = ((Get-Date) - $os.LastBootUpTime).Days
        }
    }).AddArgument($server)

    $powershell.RunspacePool = $runspacePool

    [PSCustomObject]@{
        Pipe   = $powershell
        Handle = $powershell.BeginInvoke()
    }
}

# 收集结果
foreach ($job in $jobs) {
    $result = $job.Pipe.EndInvoke($job.Handle)
    $result
    $job.Pipe.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()
```

```
Server            OS                                    LastBoot            UptimeDays
------            --                                    --------            ----------
server-01         Microsoft Windows Server 2022         2025/3/15 8:00:00          25
server-02         Microsoft Windows Server 2022         2025/4/1 10:30:00           8
server-04         Microsoft Windows Server 2019         2025/2/20 14:00:00         48
server-05         Microsoft Windows Server 2022         2025/3/28 6:15:00          12
```

## 注意事项

- `ForEach-Object -Parallel` 是 PowerShell 7 的功能，在 Windows PowerShell 5.1 中不可用
- 并行脚本块中运行在独立的运行空间中，不能直接共享变量状态，需要使用 `$using:` 或其他机制传递数据
- 合理设置 `-ThrottleLimit`，一般不超过 CPU 核心数的 2-4 倍，避免上下文切换开销过大
- 并行处理会产生多个运行空间，内存消耗会比顺序处理更高
- 对于 I/O 密集型任务（网络请求、文件读写），并行效果最明显；对于 CPU 密集型任务，收益有限
- 并行执行时输出顺序不确定，如需保持顺序，请在结果中附加原始索引后排序
- 在并行脚本块中避免写入同一个文件，否则可能出现文件锁冲突
