---
layout: post
date: 2025-07-09 08:00:00
updated: 2025-07-09 08:00:00
title: "PowerShell 技能连载 - 异步编程模式"
description: PowerTip of the Day - Asynchronous Programming Patterns in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- async
- runspace
- jobs
- parallel
---

_适用于 PowerShell 5.1 及以上版本，并行功能需要 PowerShell 7_

运维脚本经常面临 IO 等待——网络请求、文件操作、数据库查询，这些操作的响应时间往往远超 CPU 处理时间。如果顺序执行 100 个 HTTP 健康检查，每个耗时 1 秒，总共需要 100 秒；但如果并发执行，可能只需要几秒。PowerShell 提供了多种异步编程机制：后台作业（Jobs）、运行空间（Runspaces）、`ForEach-Object -Parallel`、以及 .NET 的异步 API。

本文将讲解 PowerShell 中的异步编程模式及其适用场景。

## 后台作业（Jobs）

```powershell
# Start-Job：在后台运行脚本块
$job = Start-Job -ScriptBlock {
    Start-Sleep -Seconds 2
    Get-Process | Select-Object Name, Id, CPU | Sort-Object CPU -Descending | Select-Object -First 5
}

Write-Host "作业已启动，ID：$($job.Id)" -ForegroundColor Cyan

# 非阻塞检查状态
while ($job.State -eq 'Running') {
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 500
}
Write-Host

# 获取结果
$result = Receive-Job -Job $job
Write-Host "作业完成，结果："
$result | Format-Table -AutoSize

# 清理作业
Remove-Job -Job $job

# 批量后台作业
$servers = @("SRV01", "SRV02", "SRV03", "SRV04", "SRV05")
$jobs = foreach ($server in $servers) {
    Start-Job -ScriptBlock {
        param($computer)
        $os = Get-CimInstance Win32_OperatingSystem -ComputerName $computer -ErrorAction SilentlyContinue
        if ($os) {
            [PSCustomObject]@{
                Server  = $computer
                OS      = $os.Caption
                Version = $os.Version
                Status  = "Online"
            }
        } else {
            [PSCustomObject]@{
                Server  = $computer
                OS      = "N/A"
                Version = "N/A"
                Status  = "Offline"
            }
        }
    } -ArgumentList $server
}

Write-Host "启动了 $($jobs.Count) 个后台作业" -ForegroundColor Cyan

# 等待所有作业完成
$jobs | Wait-Job | Out-Null

# 收集所有结果
$allResults = $jobs | Receive-Job
$allResults | Format-Table -AutoSize

# 清理
$jobs | Remove-Job
```

执行结果示例：

```
作业已启动，ID：15
...

作业完成，结果：
Name         Id    CPU
----         --    ---
chrome    12345 1250.3
vscode    12346  456.7
powershell 12347  234.5
node      12348  123.4
dotnet    12349   98.1

启动了 5 个后台作业

Server OS                                     Version     Status
------ --                                     -------     ------
SRV01  Microsoft Windows Server 2022 Standard 10.0.20348  Online
SRV02  Microsoft Windows Server 2022 Standard 10.0.20348  Online
SRV03  N/A                                    N/A         Offline
SRV04  Microsoft Windows Server 2019 Standard 10.0.17763  Online
SRV05  Microsoft Windows Server 2022 Standard 10.0.20348  Online
```

## ForEach-Object -Parallel

```powershell
# PowerShell 7 并行执行（推荐方式）
$servers = @("SRV01", "SRV02", "SRV03", "SRV04", "SRV05", "SRV06", "SRV07", "SRV08")

$sw = [System.Diagnostics.Stopwatch]::StartNew()

$results = $servers | ForEach-Object -Parallel {
    $server = $_
    try {
        $response = Invoke-WebRequest -Uri "http://${server}:8080/health" `
            -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        [PSCustomObject]@{
            Server    = $server
            Status    = "Healthy"
            Code      = $response.StatusCode
            LatencyMs = $response.RawContentLength
        }
    } catch {
        [PSCustomObject]@{
            Server    = $server
            Status    = "Unhealthy"
            Code      = 0
            LatencyMs = 0
            Error     = $_.Exception.Message
        }
    }
} -ThrottleLimit 4

$sw.Stop()

$results | Format-Table -AutoSize
Write-Host "并行检查 8 台服务器耗时：$($sw.ElapsedMilliseconds)ms" -ForegroundColor Green

# 共享变量（需要 $using:）
$threshold = 80
$results = $servers | ForEach-Object -Parallel {
    $server = $_
    $cpu = Get-Random -Min 10 -Max 95
    [PSCustomObject]@{
        Server   = $server
        CPU      = $cpu
        IsAlert  = $cpu -gt $using:threshold
    }
} -ThrottleLimit 4

$results | Where-Object { $_.IsAlert } | Format-Table -AutoSize
```

执行结果示例：

```
Server Status    Code LatencyMs
------ ------    ---- ---------
SRV01  Healthy   200        256
SRV02  Healthy   200        256
SRV03  Unhealthy   0          0
SRV04  Healthy   200        256
SRV05  Healthy   200        256
SRV06  Healthy   200        256
SRV07  Unhealthy   0          0
SRV08  Healthy   200        256

并行检查 8 台服务器耗时：2150ms

Server CPU IsAlert
------ --- -------
SRV02  92    True
SRV05  87    True
```

## Runspace 池

对于需要精确控制的并发场景，使用 Runspace 池：

```powershell
function Invoke-Parallel {
    <#
    .SYNOPSIS
    使用 Runspace 池并行执行脚本块
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [object[]]$InputData,

        [int]$ThrottleLimit = 4
    )

    # 创建 Runspace 池
    $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
        1, $ThrottleLimit
    )
    $pool.Open()

    $runspaces = @()

    foreach ($item in $InputData) {
        $powershell = [System.Management.Automation.PowerShell]::Create()
        $powershell.RunspacePool = $pool

        $null = $powershell.AddScript($ScriptBlock).AddArgument($item)

        $runspaces += [PSCustomObject]@{
            Pipe   = $powershell
            Handle = $powershell.BeginInvoke()
            Input  = $item
        }
    }

    # 等待完成并收集结果
    $results = @()
    foreach ($rs in $runspaces) {
        try {
            $output = $rs.Pipe.EndInvoke($rs.Handle)
            if ($output) {
                foreach ($o in $output) {
                    $results += $o
                }
            }
        } catch {
            $results += [PSCustomObject]@{
                Error  = $true
                Input  = $rs.Input
                Message = $_.Exception.Message
            }
        } finally {
            $rs.Pipe.Dispose()
        }
    }

    $pool.Close()
    $pool.Dispose()

    return $results
}

# 使用 Runspace 池并行 ping
$servers = 1..20 | ForEach-Object { "192.168.1.$_" }

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$results = Invoke-Parallel -ScriptBlock {
    param($ip)
    $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
    [PSCustomObject]@{ IP = $ip; Online = $ping }
} -InputData $servers -ThrottleLimit 10
$sw.Stop()

$online = ($results | Where-Object { $_.Online }).Count
Write-Host "扫描 20 个 IP，$online 个在线，耗时：$($sw.ElapsedMilliseconds)ms" -ForegroundColor Green
$results | Where-Object { $_.Online } | Format-Table -AutoSize
```

执行结果示例：

```
扫描 20 个 IP，8 个在线，耗时：3200ms

IP           Online
--           ------
192.168.1.1   True
192.168.1.2   True
192.168.1.10  True
192.168.1.11  True
192.168.1.12  True
192.168.1.20  True
192.168.1.50  True
192.168.1.100 True
```

## 异步文件操作

```powershell
# 并行处理文件
$files = Get-ChildItem "C:\Logs" -Filter "*.log" -Recurse | Select-Object -First 20

$sw = [System.Diagnostics.Stopwatch]::StartNew()

$fileStats = $files | ForEach-Object -Parallel {
    $file = $_
    $lines = 0
    $errors = 0

    $reader = [System.IO.StreamReader]::new($file.FullName)
    while ($null -ne $reader.ReadLine()) {
        $lines++
    }
    $reader.Close()

    [PSCustomObject]@{
        Name     = $file.Name
        SizeKB   = [math]::Round($file.Length / 1KB, 1)
        Lines    = $lines
        Modified = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    }
} -ThrottleLimit 4

$sw.Stop()

$fileStats | Format-Table -AutoSize
Write-Host "并行处理 $($files.Count) 个文件耗时：$($sw.ElapsedMilliseconds)ms" -ForegroundColor Green
```

执行结果示例：

```
Name               SizeKB Lines Modified
----               ------- ----- --------
app-20250709.log    1024.5 12050 2025-07-09 08:30
app-20250708.log     856.3  9876 2025-07-08 23:59
app-20250707.log     743.1  8543 2025-07-07 23:59
security-20250709.log  456.7  5432 2025-07-09 08:15

并行处理 20 个文件耗时：850ms
```

## 注意事项

1. **Jobs 开销大**：每个 Job 启动新的 PowerShell 进程，开销较大。少量任务用 Jobs，大量任务用 Runspace 或 `-Parallel`
2. **线程安全**：并行操作中不要直接修改共享变量，使用 `ConcurrentDictionary` 或收集结果后统一处理
3. **ThrottleLimit**：设置合理的并发限制，过多并发会导致资源争用和 API 限流
4. **错误处理**：并行任务中的错误不会自动传播到主线程，需要显式捕获和收集
5. **$using: 作用域**：`ForEach-Object -Parallel` 中访问外部变量需要 `$using:` 前缀
6. **Runspace 清理**：使用完 Runspace 和 RunspacePool 后必须调用 `Dispose()` 释放资源
