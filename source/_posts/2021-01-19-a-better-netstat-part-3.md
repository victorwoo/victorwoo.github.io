---
layout: post
date: 2021-01-19 00:00:00
title: "PowerShell 技能连载 - 更好的 NetStat（第 3 部分）"
description: PowerTip of the Day - A Better NetStat (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们介绍了 `Get-NetTCPConnection` cmdlet，它是 Windows 系统上网络实用程序 netstat.exe 的更好替代方法，并且通过一些技巧，您甚至可以解析 IP 地址和进程 ID。但是，这会大大降低命令的速度，因为 DNS 查找可能会花费一些时间，尤其是在网络超时的情况下。

让我们研究一下新的 PowerShell 7 并行处理功能如何加快处理速度。

以下是具有传统顺序处理的原始代码，该代码转储所有连接到端口 443 并解析主机名和进程（缓慢）：

```powershell
$Process = @{
    Name='Process'
    Expression={
        # return process path
        (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path

        }
}

$HostName = @{
    Name='Host'
    Expression={
        $remoteHost = $_.RemoteAddress
        try {
            # try to resolve IP address
            [Net.Dns]::GetHostEntry($remoteHost).HostName
        } catch {
            # if that fails, return IP anyway
            $remoteHost
        }
    }
}

# get all connections to port 443 (HTTPS)
Get-NetTCPConnection -RemotePort 443 -State Established |
  # where there is a remote address
  Where-Object RemoteAddress |
  # and resolve IP and Process ID
  Select-Object -Property $HostName, OwningProcess, $Process
```

这是一种利用 PowerShell 7 中新的“并行循环”功能的方法（快速）：

```powershell
# get all connections to port 443 (HTTPS)
Get-NetTCPConnection -RemotePort 443 -State Established |
  # where there is a remote address
  Where-Object RemoteAddress |
  # start parallel processing here
  # create a loop that runs with 80 consecutive threads
  ForEach-Object -ThrottleLimit 80 -Parallel {
      # $_ now represents one of the results emitted
      # by Get-NetTCPConnection
      $remoteHost = $_.RemoteAddress
      # DNS resolution occurs now in separate threads
      # at the same time
      $hostname = try {
                    # try to resolve IP address
                    [Net.Dns]::GetHostEntry($remoteHost).HostName
                  } catch {
                    # if that fails, return IP anyway
                    $remoteHost
                  }
      # compose the calculated information into one object
      [PSCustomObject]@{
        HostName = $hostname
        OwningProcess = $_.OwningProcess
        Process = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path
      }
  }
```

如您所见，第二种方法比以前快得多，并且是 PowerShell 7 中新的“并行循环”的好用例。

但是，不利的一面是，该代码现在的兼容性更低，只能在 Windows 系统上运行，并且只能在 PowerShell 7 中运行。在本系列的最后一部分中，我们将展示一个更简单的解决方案，该解决方案可以在所有版本的 PowerShell 上运行。

<!--本文国际来源：[A Better NetStat (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/a-better-netstat-part-3)-->

