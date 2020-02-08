---
layout: post
date: 2019-12-12 00:00:00
title: "PowerShell 技能连载 - Foreach -parallel (第 3 部分：批量 Ping)"
description: 'PowerTip of the Day - Foreach -parallel (Part 3: Mass Ping)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 7 中，带来了一个新的并行的 `Foreach-Object`，它可以并行执行代码并显著加快操作的速度。同样的技术可通过以下模块在 Windows PowerShell 中使用：

```powershell
Install-Module -Name PSParallel -Scope CurrentUser -Force
```

我们来看看有趣的案例。例如，如果您需要获得一个能够响应 ping (ICMP) 的计算机列表，这将需要很长时间。一个加速操作的方法是使用带超时设置的 ping，这样无需对不响应的机器等待太久。

这段代码 ping powershell.one 并且等待最长 1000 毫秒（代码来自 [https://powershell.one/tricks/network/ping](https://powershell.one/tricks/network/ping)）：

```powershell
$ComputerName = 'powershell.one'
$timeout = 1000
$ping = New-Object System.Net.NetworkInformation.Ping

$ping.Send($ComputerName, $timeout) |
    Select-Object -Property Status, @{N='IP';E={$ComputerName}}, Address
```

现在让我们来加速整件事，整批 ping 整个 IP 段！

我们先来看看在 PowerShell 7 中如何实现：

```powershell
#requires -Version 7.0

# IP range to ping
$IPAddresses = 1..255 | ForEach-Object {"192.168.0.$_"}

# timeout in milliseconds
$timeout = 1000

# number of simultaneous pings
$throttleLimit = 80

# measure execution time
$start = Get-Date

$result = $IPAddresses | ForEach-Object -ThrottleLimit $throttleLimit -parallel {
    $ComputerName = $_
    $ping = [System.Net.NetworkInformation.Ping]::new()

    $ping.Send($ComputerName, $using:timeout) |
        Select-Object -Property Status, @{N='IP';E={$ComputerName}}, Address
    } | Where-Object Status -eq Success

$end = Get-Date
$time = ($end - $start).TotalMilliseconds

Write-Warning "Execution Time $time ms"

$result
```

在 5 秒钟左右，整个 IP 段都 ping 完毕，并且返回会 ICMP 请求的 IP 地址。

在 Windows PowerShell 中，这段代码基本差不多（假设您已从 PowerShell Gallery 中安装了 PSParallel 模块）：

```powershell
#requires -Modules PSParallel
#requires -Version 3.0

# IP range to ping
$IPAddresses = 1..255 | ForEach-Object {"192.168.0.$_"}

# number of simultaneous pings
$throttleLimit = 80

# measure execution time
$start = Get-Date

$result = $IPAddresses | Invoke-Parallel -ThrottleLimit $throttleLimit -ScriptBlock {
    $ComputerName = $_
    # timeout in milliseconds
    $timeout = 1000

    $ping = New-Object -TypeName System.Net.NetworkInformation.Ping

    $ping.Send($ComputerName, $timeout) |
        Select-Object -Property Status, @{N='IP';E={$ComputerName}}, Address
    } | Where-Object Status -eq Success

$end = Get-Date
$time = ($end - $start).TotalMilliseconds

Write-Warning "Execution Time $time ms"

$result
```

与 `ForEach-Object` 不同，代码使用的是 `Invoke-Parallel`，而且由于 `Invoke-Parallel` 不支持 "`use:`" 前缀，所以所有局部变量都必须包含在脚本块中（在我们的示例中，是变量`$timeout`）。

`Invoke-Parallel` 支持一个友好的进度条，这样您可以知道有多少个任务正在并行执行。

<!--本文国际来源：[Foreach -parallel (Part 3: Mass Ping)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/foreach--parallel-part-3-mass-ping)-->

